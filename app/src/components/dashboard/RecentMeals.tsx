const meals = [
  {
    type: 'Lunch',
    time: 'Today, 12:30 PM',
    cost: '$3.50',
    initial: 'L',
    color: 'bg-orange-100 text-orange-600',
  },
  {
    type: 'Breakfast',
    time: 'Today, 8:15 AM',
    cost: '$2.50',
    initial: 'B',
    color: 'bg-blue-100 text-blue-600',
  },
  {
    type: 'Dinner',
    time: 'Yesterday, 7:45 PM',
    cost: '$4.00',
    initial: 'D',
    color: 'bg-purple-100 text-purple-600',
  },
];

export default function RecentMeals() {
  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">Recent Meals</h3>
      <div className="space-y-3">
        {meals.map((meal, index) => (
          <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div className="flex items-center space-x-3">
              <div className={`w-8 h-8 ${meal.color} rounded-full flex items-center justify-center`}>
                <span className="text-sm font-medium">{meal.initial}</span>
              </div>
              <div>
                <p className="font-medium text-gray-800">{meal.type}</p>
                <p className="text-sm text-gray-500">{meal.time}</p>
              </div>
            </div>
            <span className="text-sm font-medium text-gray-600">{meal.cost}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
