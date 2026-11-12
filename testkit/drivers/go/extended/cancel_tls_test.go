package doorman_test

import (
	"bytes"
	"crypto/tls"
	"net"
	"net/url"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var poolerAddr = getPoolerAddr()

func getPoolerAddr() string {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		return "127.0.0.1:6433" // fallback for local testing
	}
	u, err := url.Parse(dbURL)
	if err != nil {
		return "127.0.0.1:6433"
	}
	return u.Host
}

func TestCancelTLSQuery(t *testing.T) {
	// login
	connQ, errConnQ := net.Dial("tcp", poolerAddr)
	require.NoError(t, errConnQ)
	defer connQ.Close()
	t.Logf("connection query: address is %s", connQ.LocalAddr().String())
	processID, secretID := login(t, connQ, "example_user_1", "example_db", "test")
	{
		configureFlush(t, connQ, 100*time.Millisecond)
		t.Logf("connection query: send sleep\n")
		sendParseQuery(t, connQ, "select pg_sleep(10);")
		sendBindMessage(t, connQ)
		sendDescribe(t, connQ, "P")
		sendExecute(t, connQ)
		sendSyncMessage(t, connQ)
		time.Sleep(200 * time.Millisecond)
	}

	// send cancel.
	connC, errConnC := net.Dial("tcp", poolerAddr)
	require.NoError(t, errConnC)
	t.Logf("connection cancel: address is %s", connC.LocalAddr().String())
	defer connC.Close()

	{ // ssl
		t.Logf("connection cancel: send ssl request\n")
		pack := make([]byte, 0)
		pack = append(pack, i32ToBytes(8)...)
		pack = append(pack, i32ToBytes(80877103)...) // ssl request
		size, errW := connC.Write(pack)
		assert.NoError(t, errW)
		assert.Equal(t, len(pack), size)
		count, errR := connC.Read(pack)
		assert.NoError(t, errR)
		assert.Equal(t, count, 1)
		assert.Equal(t, string(pack[0]), "S")
	}

	{ // write cancel via tls.
		pgConnSSL := tls.Client(connC, &tls.Config{MinVersion: tls.VersionTLS12, InsecureSkipVerify: true})
		t.Logf("connection cancel (tls): write cancel")
		pack := make([]byte, 0)
		pack = append(pack, i32ToBytes(16)...)
		pack = append(pack, i32ToBytes(80877102)...) // cancel
		pack = append(pack, i32ToBytes(int32(processID))...)
		pack = append(pack, i32ToBytes(int32(secretID))...)
		count, errWrite := pgConnSSL.Write(pack)
		assert.NoError(t, errWrite)
		assert.Equal(t, len(pack), count)
		assert.Nil(t, pgConnSSL.Close())
	}

	{ // read response: ParseComplete/BindComplete/RowDescription may arrive in
		// an earlier TCP chunk than the cancel ErrorResponse — accumulate reads
		// until 57014 shows up or the deadline hits, then assert on the stream.
		t.Logf("connection query: read sleep\n")
		var stream []byte
		deadline := time.Now().Add(5 * time.Second) // pg_sleep(10) ⇒ x2 margin
		for time.Now().Before(deadline) {
			_ = connQ.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
			buf := make([]byte, 4096)
			n, errRead := connQ.Read(buf)
			if n > 0 {
				stream = append(stream, buf[:n]...)
				if bytes.Contains(stream, []byte("57014")) {
					break
				}
			}
			if errRead != nil {
				if ne, ok := errRead.(net.Error); ok && ne.Timeout() {
					continue // still waiting for the cancel to land
				}
				assert.NoError(t, errRead) // pooler dropped the connection
				break
			}
		}
		require.NotEmpty(t, stream, "no response within 5s — cancel over TLS was lost")
		assert.Contains(t, string(stream), "57014")
		assert.Contains(t, string(stream), "ProcessInterrupts")
	}
}

func configureFlush(t *testing.T, conn net.Conn, duration time.Duration) {
	tcpConn, ok := conn.(*net.TCPConn)
	assert.True(t, ok)
	assert.Nil(t, tcpConn.SetWriteDeadline(time.Now().Add(duration)))
}
