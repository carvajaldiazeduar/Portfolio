import './globals.css'

export const metadata = {
  title: 'Password Generator',
  description: 'A password generator built with Next.js',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
