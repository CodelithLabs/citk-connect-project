import Link from 'next/link';
import { FaGithub, FaLinkedin, FaEnvelope, FaPhone } from 'react-icons/fa';

const Footer = () => {
  const socialLinks = [
    { href: '#', icon: <FaGithub size={24} />, label: 'Github' },
    { href: '#', icon: <FaLinkedin size={24} />, label: 'LinkedIn' },
  ];

  const contactInfo = [
    { href: 'mailto:info@citkconnect.com', icon: <FaEnvelope size={20} />, text: 'info@citkconnect.com' },
    { href: 'tel:+1234567890', icon: <FaPhone size={20} />, text: '+1 (234) 567-890' },
  ];

  return (
    <footer className="bg-surface-dark text-on-surface-variant">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="md:col-span-1">
            <h3 className="text-lg font-semibold text-on-background mb-4">CITK Connect</h3>
            <p className="text-sm">The future of campus life, powered by AI. Built for the Google Hackathon to solve real-world problems for students.</p>
          </div>
          <div className="md:col-span-1">
            <h3 className="text-lg font-semibold text-on-background mb-4">Quick Links</h3>
            <ul className="space-y-2">
              <li><Link href="#features" className="hover:text-g-blue transition duration-300">Features</Link></li>
              <li><Link href="#team" className="hover:text-g-blue transition duration-300">Team</Link></li>
              <li><Link href="#hackathon" className="hover:text-g-blue transition duration-300">Hackathon</Link></li>
            </ul>
          </div>
          <div className="md:col-span-1">
            <h3 className="text-lg font-semibold text-on-background mb-4">Contact & Social</h3>
            <div className="space-y-3 mb-4">
              {contactInfo.map((item, index) => (
                <a key={index} href={item.href} className="flex items-center space-x-3 hover:text-g-blue transition duration-300">
                  {item.icon}
                  <span>{item.text}</span>
                </a>
              ))}
            </div>
            <div className="flex space-x-4">
              {socialLinks.map((link, index) => (
                <a key={index} href={link.href} aria-label={link.label} className="hover:text-g-blue transition duration-300">
                  {link.icon}
                </a>
              ))}
            </div>
          </div>
        </div>
        <div className="mt-8 border-t border-gray-700 pt-8 text-center text-sm">
          <p>&copy; {new Date().getFullYear()} CITK Connect. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
