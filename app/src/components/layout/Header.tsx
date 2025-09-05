import { BookOpenIcon } from '@heroicons/react/24/outline';
import Link from 'next/link';

export default function Header() {
  return (
    <header className="bg-white shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <div className="flex items-center space-x-4">
            <div className="w-10 h-10 bg-indigo-600 rounded-lg flex items-center justify-center">
              <BookOpenIcon className="w-6 h-6 text-white" />
            </div>
            <h1 className="text-xl font-bold text-gray-800">Meal Platform</h1>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-gray-600 hidden sm:block">Welcome, Admin!</span>
            <Link
              href="/"
              className="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition duration-200 text-sm font-medium"
            >
              Logout
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
