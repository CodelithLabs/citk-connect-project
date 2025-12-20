document.addEventListener('DOMContentLoaded', () => {
    const registerForm = document.getElementById('register-form');
    const statusSelect = document.getElementById('student-status');

    // Dynamic Form Logic
    // If user selects "Senior", maybe we ask for Roll Number immediately to verify
    statusSelect.addEventListener('change', (e) => {
        const value = e.target.value;
        if(value === 'senior') {
            // In a real app, you might unhide a 'Roll Number' field here
            console.log("Senior selected - Verification logic would trigger here");
        }
    });

    registerForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        // Simple visual feedback
        const btn = document.querySelector('.btn-google-primary');
        const originalText = btn.innerHTML;
        
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creating Account...';
        btn.style.opacity = '0.7';

        // Simulate API Call
        setTimeout(() => {
            btn.innerHTML = '<i class="fas fa-check"></i> Welcome to CITK!';
            btn.style.backgroundColor = 'var(--g-green)';
            
            // Redirect to the main dashboard (from the previous step)
            setTimeout(() => {
                alert("Registration Successful! Redirecting to Dashboard...");
                // window.location.href = 'dashboard.html'; 
            }, 1000);
        }, 2000);
    });
});