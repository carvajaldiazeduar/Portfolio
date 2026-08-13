
        async function calculate() {
            const a = document.getElementById("num1").value;
            const b = document.getElementById("num2").value;
            const operator = document.getElementById("operator").value;
            const resultDiv = document.getElementById("result");

            try {
                const res = await fetch("/calculate", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ a, b, operator }),
                });
                const data = await res.json();
                if (res.ok) {
                    resultDiv.className = "";
                    resultDiv.textContent = `Result: ${data.result}`;
                } else {
                    resultDiv.className = "error";
                    resultDiv.textContent = `Error: ${data.error}`;
                }
            } catch (err) {
                resultDiv.className = "error";
                resultDiv.textContent = "Error: Connection failed";
            }
        }
    
