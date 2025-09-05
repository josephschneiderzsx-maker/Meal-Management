import StatCard from '@/components/dashboard/StatCard';
import ConsumptionChart from '@/components/dashboard/ConsumptionChart';
import RecentMeals from '@/components/dashboard/RecentMeals';
import {
  BanknotesIcon,
  ChartPieIcon,
  ClockIcon,
  CheckBadgeIcon,
} from '@heroicons/react/24/outline';

export default function DashboardPage() {
  return (
    <div className="fade-in">
      <div className="mb-8">
        <h2 className="text-3xl font-bold text-gray-800 mb-2">Dashboard</h2>
        <p className="text-gray-600">Overview of meal consumption and deductions</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="This Month"
          value="47 meals"
          icon={ChartPieIcon}
          color="blue"
        />
        <StatCard
          title="Total Deduction"
          value="$142.50"
          icon={BanknotesIcon}
          color="red"
        />
        <StatCard
          title="Remaining Limit"
          value="13 meals"
          icon={CheckBadgeIcon}
          color="green"
        />
        <StatCard
          title="Avg. Daily"
          value="2.1 meals"
          icon={ClockIcon}
          color="purple"
        />
      </div>

      {/* Charts and Recent Meals */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <ConsumptionChart />
        <RecentMeals />
      </div>
    </div>
  );
}
