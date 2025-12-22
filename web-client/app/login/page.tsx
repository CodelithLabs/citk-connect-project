'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { FaGoogle, FaPhone } from 'react-icons/fa';
import { signInWithEmailAndPassword, GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import { auth } from '@/lib/firebase';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await signInWithEmailAndPassword(auth, email, password);
      router.push('/');
    } catch (error: any) {
      setError(error.message);
    }
  };

  const handleGoogleSignIn = async () => {
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
      router.push('/');
    } catch (error: any) {
      setError(error.message);
    }
  };

  return (
    <div className="min-h-screen bg-bg-dark flex flex-col justify-center items-center">
      <div className="max-w-md w-full mx-auto">
        <div className="bg-surface-dark shadow-lg rounded-lg p-8 m-4">
          <div className="text-center mb-8">
            <Link href="/" className="flex items-center justify-center space-x-4">
              <svg className="h-8 w-8 text-g-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 11c-1.657 0-3-1.343-3-3s1.343-3 3-3 3 1.343 3 3-1.343 3-3 3zm0 2c-2.21 0-4 1.79-4 4h8c0-2.21-1.79-4-4-4z" />
              </svg>
              <h1 className="text-3xl font-bold">CITK Connect</h1>
            </Link>
            <h2 className="mt-4 text-2xl font-extrabold">Login to your account</h2>
          </div>

          {error && <p className="text-red-500 text-center mb-4">{error}</p>}

          <form className="space-y-6" onSubmit={handleLogin}>
            <div>
              <label htmlFor="email" className="sr-only">Email address</label>
              <input id="email" name="email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} className="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-700 bg-bg-dark placeholder-gray-500 text-on-background focus:outline-none focus:ring-g-blue focus:border-g-blue focus:z-10 sm:text-sm" placeholder="Email address" />
            </div>
            <div className="flex items-center justify-between">
              <Link href="/forgot-email" className="text-sm text-g-blue hover:underline">Forgot email?</Link>
              <Link href="/forgot-password" className="text-sm text-g-blue hover:underline">Forgot password?</Link>
            </div>
            <div>
              <label htmlFor="password" className="sr-only">Password</label>
              <input id="password" name="password" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} className="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-700 bg-bg-dark placeholder-gray-500 text-on-background focus:outline-none focus:ring-g-blue focus:border-g-blue focus:z-10 sm:text-sm" placeholder="Password" />
            </div>
            <button type="submit" className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-g-blue hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
              Login
            </button>
          </form>

          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-700"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-surface-dark text-on-surface-variant">Or continue with</span>
              </div>
            </div>

            <div className="mt-6 grid grid-cols-1 gap-3">
              <div>
                <button onClick={handleGoogleSignIn} className="w-full inline-flex justify-center py-2 px-4 border border-gray-700 rounded-md shadow-sm bg-surface-dark text-sm font-medium text-on-surface-variant hover:bg-gray-700">
                  <FaGoogle className="w-5 h-5 mr-2" />
                  Sign in with Google
                </button>
              </div>
              <div>
                <a href="#" className="w-full inline-flex justify-center py-2 px-4 border border-gray-700 rounded-md shadow-sm bg-surface-dark text-sm font-medium text-on-surface-variant hover:bg-gray-700">
                  <FaPhone className="w-5 h-5 mr-2" />
                  Sign in with phone number
                </a>
              </div>
            </div>
          </div>

          <div className="mt-6 text-center">
            <p className="text-sm text-on-surface-variant">New to CITK Connect? <Link href="/signup" className="text-g-blue hover:underline">Create an account</Link></p>
          </div>
        </div>
      </div>
    </div>
  );
}
