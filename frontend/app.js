const API_URL = 'https://crackers-erp-api.onrender.com/api';

async function saveCustomer() {
  const name = document.getElementById('custName').value.trim();
  const mobile = document.getElementById('custMobile').value.trim();
  const gstin = document.getElementById('custGstin').value.trim();
  
  if (!name) {
    alert("Customer name is required");
    return;
  }

  const payload = {
    name, mobile, gstin
  };

  try {
    const res = await fetch(`${API_URL}/customers`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    
    if (res.ok) {
      const data = await res.json();
      const msgBox = document.getElementById('statusMessage');
      msgBox.innerText = `Customer ${data.name} saved successfully to PostgreSQL!`;
      msgBox.classList.remove('hidden');
      
      setTimeout(() => {
        msgBox.classList.add('hidden');
      }, 3000);
      
      // Clear inputs
      document.getElementById('custName').value = '';
      document.getElementById('custMobile').value = '';
      document.getElementById('custGstin').value = '';
    } else {
      const errorData = await res.json();
      alert(`Error saving customer: ${errorData.error}`);
    }
  } catch (error) {
    alert(`Network Error: ${error.message}. Make sure Node.js and PostgreSQL are running!`);
  }
}

function syncWithDatabase() {
  alert("Sync mechanism would pull all PostgreSQL records into the UI context here.");
}
