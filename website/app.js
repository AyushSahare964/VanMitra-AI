/* ═══════════════════════════════════════════════════════════════
   VanMitra-AI — app.js
   Interactive behaviors, scroll animations, video speed control
   ═══════════════════════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', () => {
  // ── 1. Navbar Scroll Effect ──
  const navbar = document.getElementById('navbar');
  if (navbar) {
    window.addEventListener('scroll', () => {
      navbar.classList.toggle('scrolled', window.scrollY > 50);
    }, { passive: true });
  }

  // ── 2. Hamburger Mobile Menu ──
  const hamburger = document.getElementById('hamburger');
  const navLinks = document.getElementById('navLinks');
  if (hamburger && navLinks) {
    hamburger.addEventListener('click', () => {
      const isOpen = navLinks.classList.toggle('open');
      const spans = hamburger.querySelectorAll('span');
      if (spans.length >= 3) {
        spans[0].style.transform = isOpen ? 'rotate(45deg) translate(5px, 5px)' : '';
        spans[1].style.opacity = isOpen ? '0' : '1';
        spans[2].style.transform = isOpen ? 'rotate(-45deg) translate(5px, -5px)' : '';
      }
    });

    navLinks.querySelectorAll('a').forEach(a => {
      a.addEventListener('click', () => {
        navLinks.classList.remove('open');
        const spans = hamburger.querySelectorAll('span');
        spans.forEach(s => { s.style.transform = ''; s.style.opacity = ''; });
      });
    });
  }

  // ── 3. Scroll Animations (IntersectionObserver) ──
  const animObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const parent = entry.target.parentElement;
        const siblings = parent ? [...parent.querySelectorAll('[data-animate]')] : [];
        const index = siblings.indexOf(entry.target);
        setTimeout(() => {
          entry.target.classList.add('in-view');
        }, Math.max(0, index) * 100);
        animObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

  document.querySelectorAll('[data-animate]').forEach(el => animObserver.observe(el));

  // ── 4. Active Nav Highlight on Scroll ──
  const sections = document.querySelectorAll('section[id]');
  const navAnchors = document.querySelectorAll('.nav-link');
  if (sections.length && navAnchors.length) {
    window.addEventListener('scroll', () => {
      const scrollPos = window.scrollY + 120;
      sections.forEach(sec => {
        if (scrollPos >= sec.offsetTop && scrollPos < sec.offsetTop + sec.offsetHeight) {
          navAnchors.forEach(a => a.classList.remove('active'));
          const match = document.querySelector(`.nav-link[href="#${sec.id}"]`);
          if (match) match.classList.add('active');
        }
      });
    }, { passive: true });
  }

  // ── 5. Animated Hero Stats Counters ──
  const statElements = document.querySelectorAll('.stat-number');
  const targetValues = [22, 8, 4, 14];
  function animateCounter(el, target, duration = 1200) {
    let startTimestamp = null;
    const step = (timestamp) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const progress = Math.min((timestamp - startTimestamp) / duration, 1);
      const easedProgress = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(easedProgress * target);
      if (progress < 1) requestAnimationFrame(step);
      else el.textContent = target;
    };
    requestAnimationFrame(step);
  }

  if (statElements.length >= 4) {
    const statsContainer = statElements[0].closest('.hero-stats') || statElements[0];
    const statsObserver = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        statElements.forEach((el, idx) => animateCounter(el, targetValues[idx] || 10));
        statsObserver.disconnect();
      }
    }, { threshold: 0.4 });
    statsObserver.observe(statsContainer);
  }

  // ── 6. Mouse Parallax for Background Shapes ──
  const shapes = document.querySelectorAll('.shape');
  if (shapes.length) {
    window.addEventListener('mousemove', (e) => {
      const x = (e.clientX / window.innerWidth - 0.5) * 2;
      const y = (e.clientY / window.innerHeight - 0.5) * 2;
      shapes.forEach((shape, i) => {
        shape.style.transform = `translate(${x * (i + 1) * 10}px, ${y * (i + 1) * 10}px)`;
      });
    }, { passive: true });
  }

  // Active nav style injection
  const styleEl = document.createElement('style');
  styleEl.textContent = '.nav-link.active { color: #FFF !important; background: rgba(46, 204, 113, 0.2) !important; font-weight: 700 !important; }';
  document.head.appendChild(styleEl);

  // ── 7. Spotlight Video 2x Speed ──
  const spotlightVideo = document.getElementById('spotlightVideo');
  if (spotlightVideo) {
    spotlightVideo.playbackRate = 2.0;
    // Fallback if video resets speed on play/loop
    spotlightVideo.addEventListener('play', () => {
      spotlightVideo.playbackRate = 2.0;
    });
  }
});
