
        document.getElementById("passwordForm").addEventListener("submit", async function(e) {
            e.preventDefault();
            const resultDiv = document.getElementById("result");
            resultDiv.className = "result";
            resultDiv.textContent = "Generating...";

            const params = new URLSearchParams({
                length: parseInt(document.getElementById("length").value) || 16,
                uppercase: document.getElementById("use_upper").checked,
                lowercase: document.getElementById("use_lower").checked,
                numbers: document.getElementById("use_digits").checked,
                symbols: document.getElementById("use_symbols").checked
            });

            try {
                const response = await fetch("/api/generate?" + params.toString());
                const data = await response.json();
                if (response.ok) {
                    resultDiv.textContent = "Password: " + data.password;
                } else {
                    resultDiv.className = "result error";
                    const errors = data.errors || {};
                    resultDiv.textContent = "Error: " + Object.values(errors).join(", ");
                }
            } catch (err) {
                resultDiv.className = "result error";
                resultDiv.textContent = "Error: " + err.message;
            }
        });
    