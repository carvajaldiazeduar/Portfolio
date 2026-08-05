
        document.getElementById("passwordForm").addEventListener("submit", async function(e) {
            e.preventDefault();
            const resultDiv = document.getElementById("result");
            resultDiv.className = "result";
            resultDiv.textContent = "Generating...";

            const payload = {
                length: parseInt(document.getElementById("length").value) || 16,
                use_upper: document.getElementById("use_upper").checked,
                use_lower: document.getElementById("use_lower").checked,
                use_digits: document.getElementById("use_digits").checked,
                use_symbols: document.getElementById("use_symbols").checked
            };

            try {
                const response = await fetch("/api/generate", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload)
                });
                const data = await response.json();
                if (response.ok) {
                    resultDiv.textContent = "Password: " + data.password;
                } else {
                    resultDiv.className = "result error";
                    resultDiv.textContent = "Error: " + data.error;
                }
            } catch (err) {
                resultDiv.className = "result error";
                resultDiv.textContent = "Error: " + err.message;
            }
        });
    
