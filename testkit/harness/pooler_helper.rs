use cucumber::given;

use crate::world::DoormanWorld;

/// Единая точка входа атомарного теста: запускает пулер из $POOLER
/// с конфигом из директории теста. Файл называется именем пулера:
/// <dir>/odyssey.conf | <dir>/pgbouncer.ini (+ pgbouncer.userlist) | <dir>/pg_doorman.toml.
#[given(regex = r#"^pooler started with config from "([^"]+)"$"#)]
pub async fn pooler_started_with_config(world: &mut DoormanWorld, dir: String) {
    let pooler = std::env::var("POOLER")
        .expect("POOLER is not set (expected: odyssey | pgbouncer | pg_doorman)");
    let read = |file: String| {
        std::fs::read_to_string(&file).unwrap_or_else(|e| panic!("cannot read {file}: {e}"))
    };
    match pooler.as_str() {
        "odyssey" => {
            let config = read(format!("{dir}/odyssey.conf"));
            crate::odyssey_helper::start_odyssey_with_config_content(world, &config).await;
        }
        "pgbouncer" => {
            if let Ok(userlist) = std::fs::read_to_string(format!("{dir}/pgbouncer.userlist")) {
                world.pgbouncer_userlist_file = Some(crate::utils::create_temp_file(&userlist));
            }
            let config = read(format!("{dir}/pgbouncer.ini"));
            crate::pgbouncer_helper::start_pgbouncer_with_config_content(world, &config).await;
        }
        "pg_doorman" => {
            let config = read(format!("{dir}/pg_doorman.toml"));
            crate::doorman_helper::start_doorman_with_config_content(world, &config).await;
        }
        other => panic!("unknown POOLER={other} (expected: odyssey | pgbouncer | pg_doorman)"),
    }
}
