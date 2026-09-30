# Technical Documentation — Robot Framework E-Commerce Automation

This is the module-by-module reference. For the "why", read `README.md` first;
this document is the "what" and "how", for whoever has to modify this later.

## Contents

- [Architecture](#architecture)
- [Keyword reference](#keyword-reference)
- [Libraries](#libraries)
- [Test suites](#test-suites)
- [Known quirks of the target site](#known-quirks-of-the-target-site)
- [Extending the project](#extending-the-project)

## Architecture

```
                    ┌───────────────────────────┐
                    │  tests/*.robot             │  test suites
                    │  (login.robot,             │  Setup/Teardown, data rows
                    │  end_to_end_shopping.robot)│
                    └─────────────┬─────────────┘
                                  │ Resource / Library
                    ┌─────────────▼─────────────┐
                    │  resources/pages/*.resource │  Page Object Model,
                    │  (home, login, product,     │  Robot-native: locators as
                    │  cart)                       │  Variables, actions as
                    └─────────────┬─────────────┘  user-defined Keywords
                                  │ Resource
                    ┌─────────────▼─────────────┐
                    │  resources/common.resource  │  base URL/browser/timeout,
                    │                              │  Open/Close Application,
                    │                              │  Click Element Safely
                    └───────────────────────────┘

                    ┌───────────────────────────┐
                    │  libraries/AccountApi.py    │  test-account REST bootstrap
                    │  libraries/HistoryListener.py│ cross-run pass/fail tracking
                    └───────────────────────────┘  (Python libraries, imported
                                                     directly by test suites /
                                                     passed via --listener)
```

## Keyword reference

### `resources/common.resource`

- `Open Application` — opens the configured browser at `${BASE_URL}`, maximizes,
  sets the Selenium timeout.
- `Close Application` — closes the browser.
- `Click Element Safely` — waits for visibility, tries `Click Element`, and on
  `ElementClickInterceptedException` falls back to
  `Execute Javascript    arguments[0].click();    ARGUMENTS    ${element}`.
  Used for **every** click in this project (search button, add-to-cart,
  view-cart link, login button, logout link), because the site's ad slots can
  overlap any of them.

### `resources/pages/home_page.resource`

- `Go To Home Page`
- `Go To Login Page` — clicks the nav "Signup / Login" link.
- `User Should Be Logged In As <username>` — waits until the nav's "Logged in
  as ..." label *contains* the username, using `Wait Until Element Contains`
  rather than a separate wait + assert (see quirks below for why that matters).
- `Logout`

### `resources/pages/login_page.resource`

- `Login With Credentials <email> <password>`
- `Login Error Message Should Contain <text>`

### `resources/pages/product_page.resource`

- `Go To Products Page`
- `Search For Product <term>`
- `Searched Products Heading Should Be Visible`
- `Get Product Result Names` — returns a list of product names from the
  results grid, with internal whitespace collapsed to single spaces (see
  quirks below).
- `Add First Result To Cart And Go To Cart Page`

### `resources/pages/cart_page.resource`

- `Cart Should Contain Product <name>`
- `Get Cart Item Quantity <product_id>`
- `Get Cart Item Total <product_id>`

## Libraries

### `libraries/AccountApi.py` — `AccountApi`

`ROBOT_LIBRARY_SCOPE = SUITE`, so one instance is shared by every test in a
suite (needed because `Suite Setup`/`Suite Teardown` and the test cases must
see the same account).

- `Create Test Account` — POSTs to `automationexercise.com/api/createAccount`
  with a randomly generated name/email/password and the mandatory address
  fields the API requires; raises if the API doesn't return `responseCode 201`.
- `Get Test Account Email` / `Get Test Account Password` / `Get Test Account Name`
- `Delete Test Account` — DELETEs the account; best-effort (prints a warning
  rather than failing the suite if it doesn't succeed).

### `libraries/HistoryListener.py` — `HistoryListener`

A [Robot Framework Listener API v3](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#listener-interface)
implementation, passed on the command line with `--listener`, not imported by
any test. Two hooks:

- `end_test(data, result)` — appends one JSON line to `results/history.jsonl`
  per test, per run: `{"timestamp", "suite", "test", "status", "elapsed_s"}`.
- `close()` — runs once, after the entire execution (including all suites)
  finishes. Reads the full history file, aggregates pass/fail counts per
  `(suite, test)`, and writes `results/dashboard.html` ranked by failure rate.

## Test suites

### `tests/login.robot`

`Suite Setup`/`Suite Teardown` create/delete one account for the whole suite.
`Test Setup`/`Test Teardown` open/close a fresh browser per test. Three tests:
a valid login, a wrong-password case, and a `[Template]`-driven pair of
invalid-credential cases (intentionally combined into one test here, since
they're minor variations of the same negative assertion — see the end-to-end
suite for when *not* to do this).

### `tests/end_to_end_shopping.robot`

Uses a suite-level `Test Template` (not a per-test `[Template]`) so that
"Shop For A Top", "Shop For A Dress", and "Shop For A Tshirt" are three
independent test cases, each with its own `Test Setup`/`Teardown` — see the
next section for why that distinction matters here specifically.

## Known quirks of the target site

Found by actually running the suite against the live site, not guessed:

1. **`[Template]` on a single test case shares one Setup/Teardown across all
   its data rows.** The first version of the end-to-end suite put `[Template]`
   directly under one test case with three search terms. Robot ran all three
   inside that *one* test, sharing one browser and one login session — the
   cart from "Top" was still present when "Dress" ran. Fixed by using a
   suite-level `Test Template` with three separately named test cases instead,
   each getting an independent `Test Setup`/`Teardown`.
2. **Ad iframes intercept clicks, anywhere on the page.** Not just the
   add-to-cart button — the search button, the "View Cart" modal link, and the
   login button have all been observed failing to a `googleads` iframe
   overlapping them mid-click. `Click Element Safely` (see above) is used
   everywhere as a result.
3. **The search-results product grid has a whitespace inconsistency.** At
   least one product name (`Sleeveless Dress`) renders with a double space on
   the search-results view that isn't present on the plain `/products` grid.
   `Get Product Result Names` normalizes this with
   `Evaluate    ' '.join("""${text}""".split())` before returning names, so a
   later exact-text cart assertion isn't tripped up by it.
4. **No fixed demo login exists.** Solved by `AccountApi` (see above) — the
   same constraint and the same fix as the sibling Selenium/pytest project,
   implemented natively for Robot this time.

## Extending the project

- **New page**: add `resources/pages/<name>_page.resource`; `*** Variables ***`
  for locators, `*** Keywords ***` for actions, `Resource ../common.resource`
  at the top for `${BASE_URL}`/`${TIMEOUT}`/`Click Element Safely`.
- **New data-driven test where each row needs its own browser/account**: use a
  suite-level `Test Template` with named `*** Test Cases ***` rows (see
  `end_to_end_shopping.robot`) — not a per-test `[Template]`.
- **New data-driven test where sharing one Setup across rows is fine**: a
  per-test `[Template]` with a `*** Keywords ***` helper (see `login.robot`'s
  `Login Rejected For Invalid Credentials`) is simpler and cheaper.
