'use client';

import {
  ChartBarIcon,
  Cog6ToothIcon,
  DocumentChartBarIcon,
  HomeIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Meal Tracking', href: '/meals', icon: ChartBarIcon },
  { name: 'Reports', href: '/reports', icon: DocumentChartBarIcon },
];

const adminNavigation = [
    { name: 'Settings', href: '/settings', icon: Cog6ToothIcon },
    { name: 'Report Schedules', href: '/schedules', icon: ClockIcon },
];

function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(' ');
}

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-white shadow-lg min-h-screen slide-in">
      <nav className="mt-8">
        <div className="px-4 space-y-2">
          {navigation.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className={classNames(
                pathname.startsWith(item.href)
                  ? 'bg-indigo-50 text-indigo-600'
                  : 'hover:bg-indigo-50 hover:text-indigo-600',
                'w-full text-left px-4 py-3 rounded-lg transition duration-200 flex items-center space-x-3'
              )}
            >
              <item.icon className="w-5 h-5" />
              <span>{item.name}</span>
            </Link>
          ))}

          {/* Admin Menu */}
          <div className="pt-4">
             <h3 className="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Admin
            </h3>
            <div className="mt-2 space-y-2">
                {adminNavigation.map((item) => (
                    <Link
                    key={item.name}
                    href={item.href}
                    className={classNames(
                        pathname.startsWith(item.href)
                        ? 'bg-indigo-50 text-indigo-600'
                        : 'hover:bg-indigo-50 hover:text-indigo-600',
                        'w-full text-left px-4 py-3 rounded-lg transition duration-200 flex items-center space-x-3'
                    )}
                    >
                    <item.icon className="w-5 h-5" />
                    <span>{item.name}</span>
                    </Link>
                ))}
            </div>
          </div>
        </div>
      </nav>
    </aside>
  );
}
