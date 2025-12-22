import Link from 'next/link';

export default function LoginPage() {
  return (
    <div className="min-h-screen bg-bg-dark flex flex-col justify-center items-center">
      <div className="max-w-md w-full mx-auto">
        <div className="text-center mb-8">
          <Link href="/" className="flex items-center justify-center space-x-4">
            <svg className="h-8 w-8 text-g-blue" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 11c-1.657 0-3-1.343-3-3s1.343-3 3-3 3 1.343 3 3-1.343 3-3 3zm0 2c-2.21 0-4 1.79-4 4h8c0-2.21-1.79-4-4-4z" />
            </svg>
            <h1 className="text-3xl font-bold">CITK Connect</h1>
          </Link>
          <h2 className="mt-4 text-2xl font-extrabold">Login to your account</h2>
        </div>

        <div className="bg-surface-dark shadow-lg rounded-lg p-8 m-4">
          <form className="space-y-6">
            <div>
              <label htmlFor="email" className="sr-only">Email address</label>
              <input id="email" name="email" type="email" autoComplete="email" required className="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-700 bg-bg-dark placeholder-gray-500 text-on-background focus:outline-none focus:ring-g-blue focus:border-g-blue focus:z-10 sm:text-sm" placeholder="Email address" />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">Password</label>
              <input id="password" name="password" type="password" autoComplete="current-password" required className="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-700 bg-bg-dark placeholder-gray-500 text-on-background focus:outline-none focus:ring-g-blue focus:border-g-blue focus:z-10 sm:text-sm" placeholder="Password" />
            </div>
            <button type="submit" className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-g-blue hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
              Login
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
