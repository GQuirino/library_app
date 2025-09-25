import React from 'react';

const TailwindExample = () => {
  return (
    <div className="max-w-md mx-auto mt-8 bg-white rounded-xl shadow-lg overflow-hidden">
      <div className="md:flex">
        <div className="p-8">
          <div className="uppercase tracking-wide text-sm text-indigo-500 font-semibold">
            Tailwind CSS
          </div>
          <h2 className="block mt-1 text-lg leading-tight font-medium text-black">
            Successfully Configured!
          </h2>
          <p className="mt-2 text-gray-500">
            This card demonstrates that Tailwind CSS is working correctly in your React application.
            You can now use all Tailwind utility classes for styling.
          </p>
          <div className="mt-4">
            <span className="inline-block bg-indigo-100 text-indigo-800 text-xs px-2 py-1 rounded-full">
              Responsive
            </span>
            <span className="inline-block bg-green-100 text-green-800 text-xs px-2 py-1 rounded-full ml-2">
              Utility-First
            </span>
            <span className="inline-block bg-purple-100 text-purple-800 text-xs px-2 py-1 rounded-full ml-2">
              Modern CSS
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TailwindExample;
