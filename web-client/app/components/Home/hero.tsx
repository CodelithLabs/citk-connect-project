'use client';
import { motion } from 'framer-motion';
import Link from 'next/link';

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-grid">
      {/* Background Glow */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-blue-600/20 rounded-full blur-[120px] -z-10" />
      
      <div className="max-w-7xl mx-auto px-6 text-center z-10 pt-20">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <span className="px-4 py-2 rounded-full glass-panel text-blue-400 text-sm font-medium mb-6 inline-block">
            🚀 The Future of Campus Life is Here
          </span>
          
          <h1 className="text-6xl md:text-8xl font-black mb-6 tracking-tight leading-tight">
            Navigate Your <br />
            <span className="text-gradient">Digital Campus</span>
          </h1>
          
          <p className="text-gray-400 text-xl md:text-2xl max-w-2xl mx-auto mb-10 leading-relaxed">
            AI-powered maps, seamless document handling, and instant senior connections. 
            All in one super-app designed for CITK students.
          </p>

          <div className="flex flex-col md:flex-row gap-4 justify-center items-center">
            <Link href="/signup" className="px-8 py-4 bg-white text-black font-bold text-lg rounded-xl hover:scale-105 transition-transform flex items-center gap-2">
              Get Started Now
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 8l4 4m0 0l-4 4m4-4H3"></path></svg>
            </Link>
            <Link href="#features" className="px-8 py-4 glass-panel text-white font-bold text-lg rounded-xl hover:bg-white/10 transition-colors">
              Explore Features
            </Link>
          </div>
        </motion.div>

        {/* Floating UI Elements Decor */}
        <motion.div 
          animate={{ y: [0, -20, 0] }}
          transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
          className="absolute top-1/3 left-10 md:left-20 glass-panel p-4 rounded-2xl hidden md:block"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-500/20 rounded-full flex items-center justify-center text-green-400 text-xl">📍</div>
            <div className="text-left">
              <p className="text-xs text-gray-400">Navigation</p>
              <p className="font-bold">Library: 200m</p>
            </div>
          </div>
        </motion.div>

        <motion.div 
          animate={{ y: [0, 20, 0] }}
          transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
          className="absolute bottom-1/4 right-10 md:right-20 glass-panel p-4 rounded-2xl hidden md:block"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-500/20 rounded-full flex items-center justify-center text-purple-400 text-xl">🎓</div>
            <div className="text-left">
              <p className="text-xs text-gray-400">Mentorship</p>
              <p className="font-bold">Senior Connected</p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}