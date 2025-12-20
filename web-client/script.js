document.addEventListener('DOMContentLoaded', () => {

    // --- ELEMENTS ---
    const authView = document.getElementById('auth-view');
    const dashboardView = document.getElementById('dashboard-view');
    const authForm = document.getElementById('auth-form');
    const navLoginBtn = document.getElementById('nav-login-btn');
    const navItems = document.querySelectorAll('.nav-item');
    const sections = document.querySelectorAll('.tab-section');

    // --- DATA: SENIORS ---
    const seniorsData = [
        { name: "Rahul Das", branch: "CSE - 3rd Year", skill: "Coding & Hostels", icon: "RD" },
        { name: "Priya Boro", branch: "Civil - Final Year", skill: "Scholarships", icon: "PB" },
        { name: "Amit Brahma", branch: "ECE - 2nd Year", skill: "Sports & Clubs", icon: "AB" },
        { name: "Sita Narzary", branch: "Food Tech - 3rd Year", skill: "Mess & Food", icon: "SN" }
    ];

    // --- DATA: DOCUMENTS ---
    const docsData = [
        { name: "Admission_Receipt.pdf", owner: "Admin", date: "Aug 20, 2025", status: "Verified" },
        { name: "Anti_Ragging_Affidavit.pdf", owner: "Me", date: "Aug 22, 2025", status: "Pending" },
        { name: "Medical_Certificate.jpg", owner: "Me", date: "Aug 22, 2025", status: "Verified" },
        { name: "Hostel_Allotment_Letter.pdf", owner: "Warden", date: "Yesterday", status: "Verified" }
    ];

    // --- AUTH LOGIC (Simulated) ---
    const handleLogin = (e) => {
        if(e) e.preventDefault();
        
        // Visual feedback on button
        const btn = e.target.tagName === 'BUTTON' ? e.target : document.querySelector('#auth-form button');
        const originalText = btn.innerText;
        btn.innerText = 'Signing in...';
        btn.style.opacity = '0.7';
        
        setTimeout(() => {
            // Switch Views
            authView.classList.add('hidden');
            dashboardView.classList.remove('hidden');
            
            // Initial Data Load
            loadSeniors();
            loadDocs();
            
            // Reset button for next time
            btn.innerText = originalText;
            btn.style.opacity = '1';
        }, 1200);
    };

    if (authForm) authForm.addEventListener('submit', handleLogin);
    if (navLoginBtn) navLoginBtn.addEventListener('click', handleLogin);

    // --- TAB NAVIGATION LOGIC ---
    window.switchTab = (tabName) => {
        // 1. Update Sidebar Active State
        navItems.forEach(item => {
            if(item.innerText.toLowerCase().includes(tabName === 'home' ? 'home' : 
               tabName === 'seniors' ? 'senior' : 
               tabName === 'docs' ? 'documents' : 'map')) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });

        // 2. Show Correct Section
        sections.forEach(section => {
            section.classList.add('hidden');
        });
        
        const activeSection = document.getElementById(`tab-${tabName}`);
        if (activeSection) {
            activeSection.classList.remove('hidden');
        }
    };

    // --- RENDER FUNCTIONS ---
    function loadSeniors() {
        const container = document.getElementById('seniors-container');
        if (container.innerHTML.trim() !== "") return;

        seniorsData.forEach(senior => {
            const card = document.createElement('div');
            card.className = 'senior-card';
            card.innerHTML = `
                <div class="senior-img">${senior.icon}</div>
                <h3>${senior.name}</h3>
                <p class="branch-text">${senior.branch}</p>
                <span class="chip-skill"><i class="fas fa-star"></i> ${senior.skill}</span>
                <div style="margin-top:15px;">
                    <button class="btn-outlined" style="font-size:0.8rem; padding: 5px 15px;">Message</button>
                </div>
            `;
            container.appendChild(card);
        });
    }

    function loadDocs() {
        const container = document.getElementById('docs-container');
        if (container.innerHTML.trim() !== "") return;

        docsData.forEach(doc => {
            const statusClass = doc.status === 'Verified' ? 'status-verified' : 'status-pending';
            const iconClass = doc.name.includes('pdf') ? 'fa-file-pdf' : 'fa-file-image';
            
            const row = document.createElement('div');
            row.className = 'doc-row';
            row.innerHTML = `
                <div style="display:flex; align-items:center;">
                    <i class="fas ${iconClass} doc-icon"></i> ${doc.name}
                </div>
                <div>${doc.owner}</div>
                <div>${doc.date}</div>
                <div><span class="status-pill ${statusClass}">${doc.status}</span></div>
            `;
            container.appendChild(row);
        });
    }
});