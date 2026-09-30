import random
import string

import requests

API_BASE = "https://automationexercise.com/api"


class AccountApi:
    """Robot Framework library that provisions and removes a throwaway test account.

    automationexercise.com has no fixed demo login, so login tests need an account
    that genuinely exists. The sibling Selenium/pytest project solves this the same
    way (see its framework/api_client.py) by calling the site's own createAccount /
    deleteAccount REST endpoints instead of driving the signup form. This is the
    same fix, written as a native Robot Framework library since these tests are
    .robot files rather than pytest.
    """

    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self):
        self._email = None
        self._password = None
        self._name = None

    def create_test_account(self):
        suffix = "".join(random.choice(string.digits) for _ in range(6))
        self._name = f"RobotQA{suffix}"
        self._email = f"qa.robot.capstone.{suffix}@mailinator.com"
        self._password = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(12))

        payload = {
            "name": self._name,
            "email": self._email,
            "password": self._password,
            "title": "Mr",
            "birth_date": "10",
            "birth_month": "5",
            "birth_year": "1995",
            "firstname": self._name,
            "lastname": "Tester",
            "company": "QA Capstone",
            "address1": "221B Baker Street",
            "address2": "",
            "country": "India",
            "zipcode": "700001",
            "state": "West Bengal",
            "city": "Kolkata",
            "mobile_number": "9" + "".join(random.choice(string.digits) for _ in range(9)),
        }
        response = requests.post(f"{API_BASE}/createAccount", data=payload, timeout=15)
        response.raise_for_status()
        body = response.json()
        if body.get("responseCode") != 201:
            raise AssertionError(f"createAccount API did not create the test user: {body}")

    def get_test_account_email(self):
        return self._email

    def get_test_account_password(self):
        return self._password

    def get_test_account_name(self):
        return self._name

    def delete_test_account(self):
        if self._email is None:
            return
        response = requests.delete(
            f"{API_BASE}/deleteAccount",
            data={"email": self._email, "password": self._password},
            timeout=15,
        )
        if response.status_code != 200:
            print(f"[teardown] could not delete test account {self._email}: {response.text}")
