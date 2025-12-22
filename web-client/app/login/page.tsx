'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { motion } from 'framer-motion';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await signInWithEmailAndPassword(auth, email, password);
      router.push('/dashboard');
    } catch (error) {
      alert('Login failed. Check console.');
    }
  };

  return (
    <div className="min-h-screen flex bg-black">
      {/* Left Side - Visual */}
      <div className="hidden lg:flex w-1/2 relative items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-blue-900/20 z-0"></div>
        <div className="absolute w-[500px] h-[500px] bg-purple-600/30 rounded-full blur-[100px] animate-pulse"></div>
        <div className="z-10 text-center p-12 glass-panel rounded-3xl border-none max-w-lg mx-auto">
          <h2 className="text-4xl font-bold mb-6">Welcome Back, <br/>Innovator.</h2>
          <p className="text-gray-300">Access the CITK digital ecosystem and manage your campus life efficiently.</p>
        </div>
      </div>

      {/* Right Side - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 lg:p-24">
        <motion.div 
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          className="w-full max-w-md"
        >
          <div className="mb-10">
            <Link href="/" className="text-gray-500 hover:text-white transition-colors mb-4 block">← Back to Home</Link>
            <h1 className="text-4xl font-bold mb-2">Sign In</h1>
            <p className="text-gray-400">Enter your details to access your account.</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-2">Email</label>
              <input 
                type="email" 
                className="w-full bg-surface border border-gray-800 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all"
                placeholder="student@citk.ac.in"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-2">Password</label>
              <input 
                type="password" 
                className="w-full bg-surface border border-gray-800 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-blue-500 transition-all"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>

            <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-4 rounded-xl transition-all shadow-lg hover:shadow-blue-900/20">
              Sign In
            </button>
          </form>

          <p className="mt-8 text-center text-gray-500">
            Don't have an account? <Link href="/signup" className="text-blue-400 hover:underline">Create one</Link>
          </p>
        </motion.div>
      </div>
    </div>
  );
}