import Link from 'next/link';
import { FaLinkedin, FaGithub } from 'react-icons/fa';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-bg-dark text-on-background">
      <header className="bg-surface-dark shadow-md">
        <div className="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <svg className="h-8 w-8 text-g-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 11c-1.657 0-3-1.343-3-3s1.343-3 3-3 3 1.343 3 3-1.343 3-3 3zm0 2c-2.21 0-4 1.79-4 4h8c0-2.21-1.79-4-4-4z" />
            </svg>
            <h1 className="text-2xl font-bold">CITK Connect</h1>
          </div>
          <nav className="hidden md:flex items-center space-x-8">
            <Link href="#features" className="text-on-surface-variant hover:text-g-blue">Features</Link>
            <Link href="#team" className="text-on-surface-variant hover:text-g-blue">Team</Link>
            <Link href="#hackathon" className="text-on-surface-variant hover:text-g-blue">Hackathon</Link>
            <div className="flex items-center space-x-4">
                <Link href="/login" className="text-on-surface-variant hover:text-g-blue">Login</Link>
                <Link href="/signup" className="bg-g-blue text-white px-4 py-2 rounded-md hover:bg-blue-700">Register</Link>
            </div>
          </nav>
        </div>
      </header>

      <main className="flex-grow">
        <section className="bg-surface-dark">
          <div className="max-w-7xl mx-auto py-20 px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-4xl font-extrabold tracking-tight sm:text-5xl md:text-6xl">
              <span className="text-g-blue">CITK Connect:</span> The Future of Campus Life
            </h2>
            <p className="mt-6 max-w-2xl mx-auto text-xl text-on-surface-variant">
              Experience a seamless, AI-powered campus environment. Built for the Google Hackathon.
            </p>
            <div className="mt-10">
              <Link href="/signup" className="bg-g-blue text-white px-8 py-3 rounded-md text-lg font-medium hover:bg-blue-700">
                Join the Community
              </Link>
            </div>
          </div>
        </section>

        <section id="features" className="py-20">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-16">
              <h3 className="text-3xl font-extrabold">Next-Generation Features</h3>
              <p className="mt-4 text-lg text-on-surface-variant">Leveraging the power of AI to create a smarter campus.</p>
            </div>
            <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-3">
              <div className="bg-surface-dark p-8 rounded-lg shadow-lg">
                <h4 className="text-xl font-bold text-g-green">AI-Powered Campus Map</h4>
                <p className="mt-4 text-on-surface-variant">Our 3D map with AI-powered routing helps you navigate the campus effortlessly.</p>
              </div>
              <div className="bg-surface-dark p-8 rounded-lg shadow-lg">
                <h4 className="text-xl font-bold text-g-yellow">Smart Document Assistant</h4>
                <p className="mt-4 text-on-surface-variant">An intelligent assistant to guide you through the complexities of admission paperwork.</p>
              </div>
              <div className="bg-surface-dark p-8 rounded-lg shadow-lg">
                <h4 className="text-xl font-bold text-g-red">Senior Connect</h4>
                <p className="mt-4 text-on-surface-variant">Connect with senior students for mentorship and guidance to kickstart your college journey.</p>
              </div>
            </div>
          </div>
        </section>

        <section id="team" className="bg-surface-dark py-20">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-16">
              <h3 className="text-3xl font-extrabold">Meet the Innovators</h3>
              <p className="mt-4 text-lg text-on-surface-variant">The student team behind CITK Connect.</p>
            </div>
            <div className="flex flex-wrap justify-center gap-10">
              {/* Replace with your team members */}
              <div className="text-center">
                <div className="w-32 h-32 rounded-full bg-gray-600 mx-auto mb-4"></div>
                <h4 className="text-xl font-bold">[Your Name]</h4>
                <p className="text-on-surface-variant">[Your Role]</p>
                <div className="flex justify-center space-x-4 mt-2">
                  <a href="#" className="text-on-surface-variant hover:text-g-blue"><FaLinkedin size={24} /></a>
                  <a href="#" className="text-on-surface-variant hover:text-g-blue"><FaGithub size={24} /></a>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="hackathon" className="py-20">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h3 className="text-3xl font-extrabold">Google Hackathon Submission</h3>
            <p className="mt-4 text-lg text-on-surface-variant">This project is proudly submitted for the Google Hackathon, aiming to solve real-world problems for students.</p>
          </div>
        </section>
      </main>

      <footer className="bg-surface-dark">
        <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <p>&copy; 2024 CITK Connect. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
