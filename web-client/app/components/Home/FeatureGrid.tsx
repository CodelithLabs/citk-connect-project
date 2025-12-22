'use client';
import { motion } from 'framer-motion';
import { FaMapMarkedAlt, FaRobot, FaUserGraduate, FaCalendarAlt } from 'react-icons/fa';

const features = [
  {
    title: "AI-Powered 3D Maps",
    desc: "Never get lost again. Our AR-ready maps guide you from the hostel to your classroom.",
    icon: <FaMapMarkedAlt className="text-4xl text-blue-500" />,
    colSpan: "md:col-span-2",
    bg: "bg-blue-900/10"
  },
  {
    title: "The Brain (AI Chat)",
    desc: "Instant answers to 'Where is the registrar?' or 'How do I apply for leave?'.",
    icon: <FaRobot className="text-4xl text-purple-500" />,
    colSpan: "md:col-span-1",
    bg: "bg-purple-900/10"
  },
  {
    title: "Senior Connect",
    desc: "Bridge the gap. Find mentors based on your skills and interests.",
    icon: <FaUserGraduate className="text-4xl text-green-500" />,
    colSpan: "md:col-span-1",
    bg: "bg-green-900/10"
  },
  {
    title: "Event Radar",
    desc: "Real-time updates on Hackathons, Culturals, and Exams.",
    icon: <FaCalendarAlt className="text-4xl text-pink-500" />,
    colSpan: "md:col-span-2",
    bg: "bg-pink-900/10"
  }
];

export default function FeatureGrid() {
  return (
    <section id="features" className="py-24 bg-black relative">
      <div className="max-w-7xl mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-5xl font-bold mb-4">Why CITK Connect?</h2>
          <p className="text-gray-400">Built by students, for students.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {features.map((f, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              whileHover={{ y: -5 }}
              className={`glass-panel p-8 rounded-3xl ${f.colSpan} ${f.bg} border-t border-white/10`}
            >
              <div className="mb-6">{f.icon}</div>
              <h3 className="text-2xl font-bold mb-2">{f.title}</h3>
              <p className="text-gray-400 leading-relaxed">{f.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}