import './App.css'
import  { outlet } from 'react-router-dom'
import { Header, Main, Footer } from './components'

function App() {
  
  return (
    <>
      <outlet />
    </>
  )
}

export default App
