import json
import time
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
RESULTS_DIR = ROOT_DIR / "results"
HISTORY_FILE = RESULTS_DIR / "history.jsonl"
DASHBOARD_FILE = RESULTS_DIR / "dashboard.html"


class HistoryListener:
    """Robot Framework listener that tracks pass/fail history across runs.

    log.html and report.html only ever describe a single run. What actually
    matters once this suite is wired into CI is which tests are reliable and
    which ones fail often enough to be flaky, and that only shows up by looking
    across many runs. This listener appends one line per test to
    results/history.jsonl on every execution, then rebuilds results/dashboard.html
    ranking every test seen so far by its failure rate across all of them.

    Wired in via the command line rather than a resource file, since a listener
    is run configuration, not test logic:
        robot --listener libraries/HistoryListener.py tests/
    """

    ROBOT_LISTENER_API_VERSION = 3

    def end_test(self, data, result):
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        entry = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "suite": result.parent.name,
            "test": result.name,
            "status": result.status,
            "elapsed_s": round(result.elapsed_time.total_seconds(), 2),
        }
        with HISTORY_FILE.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(entry) + "\n")

    def close(self):
        if not HISTORY_FILE.exists():
            return

        lines = [line for line in HISTORY_FILE.read_text(encoding="utf-8").splitlines() if line.strip()]
        if not lines:
            return

        records = [json.loads(line) for line in lines]
        stats = {}
        for record in records:
            key = (record["suite"], record["test"])
            bucket = stats.setdefault(
                key, {"runs": 0, "passes": 0, "fails": 0, "last_status": None, "last_seen": None}
            )
            bucket["runs"] += 1
            if record["status"] == "PASS":
                bucket["passes"] += 1
            else:
                bucket["fails"] += 1
            bucket["last_status"] = record["status"]
            bucket["last_seen"] = record["timestamp"]

        ranked = sorted(stats.items(), key=lambda item: item[1]["fails"] / item[1]["runs"], reverse=True)

        rows = []
        for (suite, test), bucket in ranked:
            flakiness = bucket["fails"] / bucket["runs"] * 100
            css_class = "pass" if bucket["last_status"] == "PASS" else "fail"
            rows.append(
                "<tr><td>{suite}</td><td>{test}</td><td>{runs}</td><td>{passes}</td>"
                "<td>{fails}</td><td>{flaky:.0f}%</td>"
                "<td class='{css_class}'>{last_status}</td><td>{last_seen}</td></tr>".format(
                    suite=suite,
                    test=test,
                    runs=bucket["runs"],
                    passes=bucket["passes"],
                    fails=bucket["fails"],
                    flaky=flakiness,
                    css_class=css_class,
                    last_status=bucket["last_status"],
                    last_seen=bucket["last_seen"],
                )
            )

        DASHBOARD_FILE.write_text(
            "<html><head><title>Test History Dashboard</title>"
            "<style>"
            "body{font-family:Arial,Helvetica,sans-serif;margin:2rem;}"
            "table{border-collapse:collapse;width:100%;}"
            "td,th{border:1px solid #ccc;padding:6px 10px;font-size:14px;text-align:left;}"
            "th{background:#222;color:#fff;}"
            ".pass{color:#1a7a1a;font-weight:bold;}"
            ".fail{color:#b00020;font-weight:bold;}"
            "</style></head><body>"
            "<h2>Test History Dashboard</h2>"
            "<p>Aggregated across every run recorded in history.jsonl, not just the most "
            "recent one. A test with a high flakiness percentage is failing intermittently "
            "and is worth investigating before it's trusted in a CI gate.</p>"
            "<table><tr><th>Suite</th><th>Test</th><th>Runs</th><th>Passes</th><th>Fails</th>"
            "<th>Flakiness</th><th>Last Result</th><th>Last Seen</th></tr>"
            f"{''.join(rows)}</table></body></html>",
            encoding="utf-8",
        )
        print(f"\nTest history dashboard written to {DASHBOARD_FILE} ({len(records)} recorded test run(s))")
