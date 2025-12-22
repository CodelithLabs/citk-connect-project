'use client';

import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { auth } from '@/lib/firebase';
import { FaBars, FaTimes } from 'react-icons/fa';
import { useState } from 'react';

const Header = () => {
  const { user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);

  const handleSignOut = async () => {
    await auth.signOut();
  };

  const navLinks = [
    { href: '#features', label: 'Features' },
    { href: '#team', label: 'Team' },
    { href: '#hackathon', label: 'Hackathon' },
  ];

  return (
    <header className="bg-surface-dark shadow-lg sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-20">
          <div className="flex-shrink-0">
            <Link href="/" className="flex items-center space-x-2">
              <svg className="h-8 w-8 text-g-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                 <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 11c-1.657 0-3-1.343-3-3s1.343-3 3-3 3 1.343 3 3-1.343 3-3 3zm0 2c-2.21 0-4 1.79-4 4h8c0-2.21-1.79-4-4-4z" />
              </svg>
              <span className="text-2xl font-bold text-on-background">CITK Connect</span>
            </Link>
          </div>
          <div className="hidden md:flex items-center space-x-8">
            {navLinks.map((link) => (
              <Link key={link.href} href={link.href} className="text-on-surface-variant hover:text-g-blue transition duration-300">
                {link.label}
              </Link>
            ))}
            {user ? (
              <div className="flex items-center space-x-4">
                <span className="text-on-surface-variant">{user.email}</span>
                <button
                  onClick={handleSignOut}
                  className="bg-g-red text-white px-4 py-2 rounded-md hover:bg-red-700 transition duration-300"
                >
                  Sign Out
                </button>
              </div>
            ) : (
              <div className="flex items-center space-x-4">
                <Link href="/login" className="text-on-surface-variant hover:text-g-blue transition duration-300">
                  Login
                </Link>
                <Link href="/signup" className="bg-g-blue text-white px-4 py-2 rounded-md hover:bg-blue-700 transition duration-300">
                  Register
                </Link>
              </div>
            )}
          </div>
          <div className="md:hidden flex items-center">
            <button onClick={() => setIsOpen(!isOpen)} className="text-on-surface-variant hover:text-g-blue">
              {isOpen ? <FaTimes size={24} /> : <FaBars size={24} />}
            </button>
          </div>
        </div>
      </div>
      {isOpen && (
        <div className="md:hidden bg-surface-dark">
          <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setIsOpen(false)}
                className="block px-3 py-2 rounded-md text-base font-medium text-on-surface-variant hover:text-white hover:bg-gray-700"
              >
                {link.label}
              </Link>
            ))}
            <div className="border-t border-gray-700 mt-4 pt-4">
              {user ? (
                <div className="flex items-center px-3">
                  <div className="ml-3">
                    <p className="text-base font-medium text-white">{user.displayName || user.email}</p>
                    <button
                      onClick={() => { handleSignOut(); setIsOpen(false); }}
                      className="mt-2 w-full text-left block px-3 py-2 rounded-md text-base font-medium text-on-surface-variant hover:text-white hover:bg-gray-700"
                    >
                      Sign Out
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-1">
                  <Link href="/login" onClick={() => setIsOpen(false)} className="block px-3 py-2 rounded-md text-base font-medium text-on-surface-variant hover:text-white hover:bg-gray-700">
                    Login
                  </Link>
                  <Link href="/signup" onClick={() => setIsOpen(false)} className="block px-3 py-2 rounded-md text-base font-medium text-on-surface-variant hover:text-white hover:bg-gray-700">
                    Register
                  </Link>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;
