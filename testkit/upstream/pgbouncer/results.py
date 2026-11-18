"""Keep an outer shell success from hiding pytest skips or an empty selection."""


def pytest_sessionfinish(session, exitstatus):
    reporter = session.config.pluginmanager.get_plugin("terminalreporter")
    stats = reporter.stats
    passed = len(stats.get("passed", []))
    failed = len(stats.get("failed", [])) + len(stats.get("error", []))
    skipped = len(stats.get("skipped", [])) + len(stats.get("xfailed", []))
    reporter.write_line(
        f"UPSTREAM_RESULT collected={session.testscollected} "
        f"passed={passed} failed={failed} skipped={skipped}"
    )
    if exitstatus == 0 and (not passed or passed != session.testscollected or skipped):
        session.exitstatus = 1
