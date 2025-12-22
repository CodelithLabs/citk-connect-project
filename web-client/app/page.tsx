import Navbar from '@/app/components/layout/Navbar';
import Hero from '@/components/home/Hero';
import FeatureGrid from '@/components/home/FeatureGrid';
import Footer from '@/app/components/layout/Footer';

export default function Home() {
  return (
    <main className="bg-background text-white selection:bg-blue-500/30">
      <Navbar />
      <Hero />
      <FeatureGrid />
      
      {/* Hackathon Badge Section */}
      <section className="py-20 border-t border-white/10 bg-black">
        <div className="max-w-4xl mx-auto text-center px-6">
          <div className="glass-panel p-8 rounded-2xl flex flex-col items-center">
            <span className="text-6xl mb-4">🏆</span>
            <h2 className="text-3xl font-bold mb-2">Google Hackathon Submission</h2>
            <p className="text-gray-400">Proudly built with Next.js, Firebase, and Gemini AI.</p>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}