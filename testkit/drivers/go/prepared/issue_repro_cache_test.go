package doorman_test

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/stretchr/testify/assert"
)

func TestIssueReproPreparedCache(t *testing.T) {
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
	assert.NoError(t, err)
	defer conn.Close(ctx)

	// Готовим 150 разных стейтментов: пулер с заявленным лимитом кеша обязан
	// вытеснять старые на сервере, иначе память бэкенда растёт без предела.
	// Пулер без лимита (odyssey) должен вести себя как прямой PG: ничего не вытеснять.
	for i := 1; i <= 150; i++ {
		stmtName := fmt.Sprintf("stmt_%d", i)
		query := fmt.Sprintf("SELECT %d", i)
		_, err := conn.Prepare(ctx, stmtName, query)
		assert.NoError(t, err)
	}

	var count int
	err = conn.QueryRow(ctx, "SELECT count(*) FROM pg_prepared_statements").Scan(&count)
	assert.NoError(t, err)

	switch os.Getenv("EXPECTED_CACHE_MODE") {
	case "limit":
		// пулер заявил лимит 100 в конфиге — на сервере не больше
		assert.LessOrEqual(t, count, 100, "пулер не вытесняет prepared-стейтменты: count=%d при заявленном лимите 100", count)
	case "nolimit":
		// лимит не заявлен — оракул (прямой PG) ничего не вытесняет в рамках сессии
		assert.GreaterOrEqual(t, count, 150, "пулер вытесняет стейтменты без заявленного лимита: count=%d, оракул хранит все 150", count)
	default:
		t.Fatal("EXPECTED_CACHE_MODE не задан (limit|nolimit)")
	}
}
