'use client';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import Navbar from '@/components/layout/Navbar';

export default function Dashboard() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) router.push('/login');
  }, [user, loading, router]);

  if (loading) return <div className="min-h-screen flex items-center justify-center bg-black">Loading...</div>;

  return (
    <div className="min-h-screen bg-black text-white">
      <Navbar />
      <div className="pt-28 px-6 max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Student Dashboard</h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Stats Column */}
          <div className="lg:col-span-2 space-y-6">
            <div className="glass-panel p-6 rounded-2xl">
              <h3 className="text-gray-400 mb-4 text-sm uppercase tracking-wider">Attendance Overview</h3>
              <div className="h-48 bg-gradient-to-r from-blue-900/20 to-purple-900/20 rounded-xl flex items-end p-4 gap-2">
                {[40, 70, 50, 90, 60, 80, 95].map((h, i) => (
                  <div key={i} style={{ height: `${h}%` }} className="flex-1 bg-blue-600/50 rounded-t-sm hover:bg-blue-500 transition-colors"></div>
                ))}
              </div>
            </div>
            
            <div className="grid grid-cols-2 gap-6">
              <div className="glass-panel p-6 rounded-2xl bg-green-900/10 border-green-500/20">
                <h3 className="text-green-400 mb-2">Assignments</h3>
                <p className="text-4xl font-bold">12 <span className="text-sm text-gray-500 font-normal">Pending</span></p>
              </div>
              <div className="glass-panel p-6 rounded-2xl bg-pink-900/10 border-pink-500/20">
                <h3 className="text-pink-400 mb-2">Events</h3>
                <p className="text-4xl font-bold">3 <span className="text-sm text-gray-500 font-normal">Upcoming</span></p>
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="glass-panel p-6 rounded-2xl h-fit">
            <h3 className="text-gray-400 mb-4 text-sm uppercase tracking-wider">Quick Actions</h3>
            <div className="space-y-3">
              <button className="w-full text-left p-3 hover:bg-white/5 rounded-lg transition-colors flex items-center gap-3">
                🤖 Ask "The Brain" AI
              </button>
              <button className="w-full text-left p-3 hover:bg-white/5 rounded-lg transition-colors flex items-center gap-3">
                🗺️ View Campus Map
              </button>
              <button className="w-full text-left p-3 hover:bg-white/5 rounded-lg transition-colors flex items-center gap-3">
                📅 Book Library Slot
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}