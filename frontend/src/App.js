import logo from './logo.svg';
import './App.css';
import TailwindExample from './components/TailwindExample';

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center">
          <img src={logo} className="mx-auto h-40 w-40 animate-spin" alt="logo" />
          <h1 className="mt-6 text-4xl font-bold text-gray-900">
            Library Management System
          </h1>
          <p className="mt-4 text-lg text-gray-600">
            React Frontend with <span className="text-indigo-600 font-semibold">Tailwind CSS</span> Successfully Configured!
          </p>
          <div className="mt-8 space-x-4">
            <button className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-6 rounded-lg shadow-md transition-colors duration-200">
              Get Started
            </button>
            <button className="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-3 px-6 rounded-lg shadow-md transition-colors duration-200">
              Learn More
            </button>
          </div>
        </header>
        <TailwindExample />
      </div>
    </div>
  );
}

export default App;
