'use client';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { motion } from 'framer-motion';
import { useState, useEffect } from 'react';

export default function Navbar() {
  const { user } = useAuth();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className={`fixed w-full z-50 transition-all duration-300 ${
        scrolled ? 'glass-panel py-4' : 'bg-transparent py-6'
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 flex justify-between items-center">
        <Link href="/" className="text-2xl font-bold tracking-tighter flex items-center gap-2">
          <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
            C
          </div>
          <span className="text-white">CITK<span className="text-blue-500">Connect</span></span>
        </Link>

        <div className="hidden md:flex gap-8 items-center">
          {['Features', 'Map', 'Events', 'Team'].map((item) => (
            <Link key={item} href={`#${item.toLowerCase()}`} className="text-gray-400 hover:text-white transition-colors text-sm uppercase tracking-wider font-medium">
              {item}
            </Link>
          ))}
        </div>

        <div className="flex gap-4">
          {user ? (
            <Link href="/dashboard" className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-full font-medium transition-all shadow-[0_0_20px_rgba(59,130,246,0.5)]">
              Dashboard
            </Link>
          ) : (
            <Link href="/login" className="border border-white/20 hover:bg-white/10 text-white px-6 py-2 rounded-full font-medium transition-all">
              Login
            </Link>
          )}
        </div>
      </div>
    </motion.nav>
  );
}