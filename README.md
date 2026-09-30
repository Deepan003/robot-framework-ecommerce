# Robot Framework E-Commerce Automation

![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.x-00C298?logo=robotframework&logoColor=white)
![SeleniumLibrary](https://img.shields.io/badge/SeleniumLibrary-6.x-43B02A?logo=selenium&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)
![CI](https://img.shields.io/badge/CI-Jenkins-D24939?logo=jenkins&logoColor=white)

Keyword-driven, data-driven automation of the login and shopping flow on
[automationexercise.com](https://automationexercise.com), built with Robot
Framework + SeleniumLibrary. This is a separate, standalone project from the
Selenium/pytest framework in `../selenium-pom-framework` — same site, different
tooling, different design.

## Contents

- [Business flow covered](#business-flow-covered)
- [Why it's built this way](#why-its-built-this-way)
- [Project layout](#project-layout)
- [Setup](#setup)
- [Running the tests](#running-the-tests)
- [What's in results/](#whats-in-results)

## Business flow covered

```
Launch Browser -> Login -> Search Product -> Add To Cart -> Verify Cart -> Logout -> Close Browser
```

`tests/login.robot` covers login in isolation (valid credentials, wrong
password, and a data-driven set of invalid-credential cases). `tests/end_to_end_shopping.robot`
runs the full flow above once per search term (Top, Dress, Tshirt).

## Why it's built this way

**Page Object Model, as Robot resource files.** Each page on the site
(`resources/pages/home_page.resource`, `login_page.resource`,
`product_page.resource`, `cart_page.resource`) owns its own locators and
user-defined keywords. Test suites call `Login With Credentials`, `Search For
Product`, `Cart Should Contain Product`, etc. — they never touch a CSS
selector directly. That's the same separation of concerns the POM pattern
gives you in code, expressed in Robot's own resource-file mechanism.

**Data-driven tests use `Test Template`, not `[Template]` on one test case.**
The first version of `end_to_end_shopping.robot` put `[Template]` directly on
a single test case with three data rows. That folds all three rows into *one*
test that shares a single `Test Setup`/`Teardown` — which in practice meant
one browser and one login session for all three search terms, and a cart that
silently carried an item over from the previous search term. Moving to a
suite-level `Test Template` with three separately named test cases fixes
that: each one gets its own fresh browser and gets torn down independently.

**No fixed demo account exists on this site.** Same real constraint the
Selenium/pytest project deals with, solved the same way but as a native Robot
library: `libraries/AccountApi.py` calls the site's own `createAccount` /
`deleteAccount` REST endpoints (documented at `/api_list`) to provision a
throwaway account in `Suite Setup` and remove it in `Suite Teardown`, instead
of driving the multi-step signup form.

**Ads on this site intercept clicks.** automationexercise.com serves live ad
slots that can slide over a button mid-click, anywhere on the page — the
search button, the add-to-cart button, and the "View Cart" link all hit this
during development. `resources/common.resource` defines `Click Element
Safely`, which tries a normal click and falls back to a JavaScript click if
Selenium reports the click was intercepted. Every clickable element in this
project goes through it.

## Project layout

```
resources/
  common.resource         base URL/browser/timeout, Open/Close Application, Click Element Safely
  pages/
    home_page.resource     nav: login link, "logged in as", logout
    login_page.resource    login form + error message
    product_page.resource  search box, results, add to cart
    cart_page.resource     cart table assertions
libraries/
  AccountApi.py           creates/deletes a throwaway account via the site's REST API
  HistoryListener.py      Robot listener: cross-run pass/fail history + flakiness dashboard
tests/
  login.robot
  end_to_end_shopping.robot
results/                  generated: log.html, report.html, output.xml, history.jsonl, dashboard.html
Jenkinsfile
```

## Setup

```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Chrome needs to be installed locally; SeleniumLibrary resolves the matching
driver automatically through Selenium Manager.

## Running the tests

```
robot --outputdir results --listener libraries/HistoryListener.py tests/
```

Or a single suite:

```
robot --outputdir results tests/login.robot
```

`results/log.html` and `results/report.html` are Robot's own run report and
detailed keyword-by-keyword log (with a screenshot auto-attached to any failed
keyword — SeleniumLibrary does this by default, no extra code needed). Passing
`--listener libraries/HistoryListener.py` additionally appends this run to
`results/history.jsonl` and rebuilds `results/dashboard.html`.

On Jenkins, the included `Jenkinsfile` installs dependencies into a venv, runs
the same command, and archives everything under `results/` regardless of
whether the build passed.

## What's in results/

| File | Produced by | Describes |
|---|---|---|
| `log.html` | Robot Framework | Every keyword this run, in order, with failure screenshots |
| `report.html` | Robot Framework | Pass/fail summary for this run |
| `output.xml` | Robot Framework | Machine-readable result of this run (what `rebot` merges/reports from) |
| `history.jsonl` | `HistoryListener` | One line per test per run, ever — the raw data behind the dashboard |
| `dashboard.html` | `HistoryListener` | Tests ranked by failure rate across every run recorded so far |

`log.html`/`report.html` answer "did it pass this time." `dashboard.html`
answers the question CI actually cares about: "is this test reliable, or does
it fail one run in five?"
