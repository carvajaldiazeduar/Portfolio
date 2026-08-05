(function () {
    const MAX_DIGITS = 15;
    const ALLOWED_OPERATORS = ["add", "subtract", "multiply", "divide"];

    const display = document.getElementById("display");
    const errorEl = document.getElementById("error");
    let currentValue = "";
    let previousValue = "";
    let operator = null;
    let waitingForNext = false;
    let calculationInProgress = false;

    function sanitizeNumber(value) {
        const num = parseFloat(value);
        if (isNaN(num) || !isFinite(num)) return null;
        return num;
    }

    function updateDisplay(value) {
        display.textContent = String(value);
    }

    function setError(message) {
        const sanitized = message.replace(/[<>&"']/g, "");
        errorEl.textContent = sanitized;
    }

    function clearError() {
        errorEl.textContent = "";
    }

    window.inputDigit = function (digit) {
        clearError();
        if (calculationInProgress) return;

        if (waitingForNext) {
            currentValue = String(digit);
            waitingForNext = false;
        } else {
            if (currentValue.replace("-", "").replace(".", "").length >= MAX_DIGITS) {
                return;
            }
            currentValue = currentValue === "" || currentValue === "0"
                ? String(digit)
                : currentValue + digit;
        }
        updateDisplay(currentValue);
    };

    window.inputDecimal = function () {
        clearError();
        if (calculationInProgress) return;

        if (waitingForNext) {
            currentValue = "0.";
            waitingForNext = false;
            updateDisplay(currentValue);
            return;
        }
        if (!currentValue.includes(".")) {
            currentValue += ".";
            updateDisplay(currentValue);
        }
    };

    window.setOperator = function (op) {
        clearError();
        if (calculationInProgress) return;

        if (!ALLOWED_OPERATORS.includes(op)) return;

        if (operator !== null) {
            window.calculateResult();
        }
        previousValue = currentValue || "0";
        operator = op;
        waitingForNext = true;
    };

    window.clearDisplay = function () {
        currentValue = "";
        previousValue = "";
        operator = null;
        waitingForNext = false;
        calculationInProgress = false;
        updateDisplay("0");
        clearError();
    };

    window.toggleSign = function () {
        if (calculationInProgress) return;
        if (currentValue && currentValue !== "0") {
            currentValue = String(parseFloat(currentValue) * -1);
            updateDisplay(currentValue);
        }
    };

    window.percent = function () {
        if (calculationInProgress) return;
        if (currentValue) {
            currentValue = String(parseFloat(currentValue) / 100);
            updateDisplay(currentValue);
        }
    };

    window.calculateResult = function () {
        clearError();
        if (operator === null || previousValue === "") return;
        if (calculationInProgress) return;

        const numA = sanitizeNumber(previousValue);
        const numB = sanitizeNumber(currentValue);

        if (numA === null || numB === null) {
            setError("Invalid number");
            return;
        }

        calculationInProgress = true;

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        fetch("/calculate", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                a: numA,
                b: numB,
                operator: operator,
            }),
            signal: controller.signal,
        })
        .then(function (response) {
            return response.json().then(function (data) {
                if (!response.ok) {
                    throw new Error(data.error || "Calculation failed");
                }
                return data;
            });
        })
        .then(function (data) {
            const result = sanitizeNumber(data.result);
            if (result === null) {
                setError("Invalid result");
                return;
            }
            currentValue = String(result);
            updateDisplay(currentValue);
            previousValue = "";
            operator = null;
            waitingForNext = false;
        })
        .catch(function (err) {
            if (err.name === "AbortError") {
                setError("Request timed out");
            } else {
                setError(err.message || "Something went wrong");
            }
        })
        .finally(function () {
            clearTimeout(timeoutId);
            calculationInProgress = false;
        });
    };
})();
