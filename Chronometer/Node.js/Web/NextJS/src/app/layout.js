import './globals.css'

export const metadata = {
  title: 'Chronometer',
  description: 'A simple chronometer built with Next.js',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
