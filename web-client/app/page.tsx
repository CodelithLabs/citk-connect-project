'use client';

import Link from 'next/link';
import { FaLinkedin, FaGithub, FaEnvelope, FaPhone } from 'react-icons/fa';
import { motion } from 'framer-motion';

const featureCards = [
  {
    title: 'AI-Powered Campus Map',
    description: 'Our 3D map with AI-powered routing helps you navigate the campus effortlessly.',
    color: 'text-g-green',
  },
  {
    title: 'Smart Document Assistant',
    description: 'An intelligent assistant to guide you through the complexities of admission paperwork.',
    color: 'text-g-yellow',
  },
  {
    title: 'Senior Connect',
    description: 'Connect with senior students for mentorship and guidance to kickstart your college journey.',
    color: 'text-g-red',
  },
];

const teamMembers = [
  {
    name: '[Your Name]',
    role: '[Your Role]',
    imageUrl: 'https://via.placeholder.com/150',
    social: {
      linkedin: '#',
      github: '#',
    },
  },
  // Add more team members here
];

const HomePage = () => {
  return (
    <div>
      {/* Hero Section */}
      <motion.section 
        initial={{ opacity: 0, y: 20 }} 
        animate={{ opacity: 1, y: 0 }} 
        transition={{ duration: 0.8 }}
        className="bg-surface-dark py-20 sm:py-32"
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl md:text-6xl font-extrabold tracking-tight">
            <span className="text-g-blue">CITK Connect:</span> The Future of Campus Life
          </h1>
          <p className="mt-6 max-w-2xl mx-auto text-lg sm:text-xl text-on-surface-variant">
            Experience a seamless, AI-powered campus environment. Built for the Google Hackathon.
          </p>
          <div className="mt-10">
            <Link 
              href="/signup" 
              className="bg-g-blue text-white px-8 py-3 rounded-md text-lg font-medium hover:bg-blue-700 transition duration-300 transform hover:scale-105"
            >
              Join the Community
            </Link>
          </div>
        </div>
      </motion.section>

      {/* Features Section */}
      <section id="features" className="py-20 sm:py-28">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-extrabold">Next-Generation Features</h2>
            <p className="mt-4 text-lg text-on-surface-variant">Leveraging the power of AI to create a smarter campus.</p>
          </div>
          <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-3">
            {featureCards.map((feature, index) => (
              <motion.div 
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="bg-surface-dark p-8 rounded-lg shadow-lg hover:shadow-2xl transition-shadow duration-300"
              >
                <h3 className={`text-xl font-bold ${feature.color}`}>{feature.title}</h3>
                <p className="mt-4 text-on-surface-variant">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Team Section */}
      <section id="team" className="bg-surface-dark py-20 sm:py-28">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-extrabold">Meet the Innovators</h2>
            <p className="mt-4 text-lg text-on-surface-variant">The student team behind CITK Connect.</p>
          </div>
          <div className="flex flex-wrap justify-center gap-10">
            {teamMembers.map((member, index) => (
              <motion.div 
                key={index}
                initial={{ opacity: 0, scale: 0.9 }} 
                whileInView={{ opacity: 1, scale: 1 }} 
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="text-center"
              >
                <img src={member.imageUrl} alt={member.name} className="w-32 h-32 rounded-full mx-auto mb-4 border-4 border-g-blue"/>
                <h3 className="text-xl font-bold">{member.name}</h3>
                <p className="text-on-surface-variant">{member.role}</p>
                <div className="flex justify-center space-x-4 mt-2">
                  <a href={member.social.linkedin} className="text-on-surface-variant hover:text-g-blue transition-colors"><FaLinkedin size={24}/></a>
                  <a href={member.social.github} className="text-on-surface-variant hover:text-g-blue transition-colors"><FaGithub size={24}/></a>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Hackathon Section */}
      <section id="hackathon" className="py-20 sm:py-28">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl sm:text-4xl font-extrabold">Google Hackathon Submission</h2>
          <p className="mt-4 text-lg text-on-surface-variant">This project is proudly submitted for the Google Hackathon, aiming to solve real-world problems for students.</p>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
