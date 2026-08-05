import './globals.css'

export const metadata = {
  title: 'Contacts',
  description: 'A simple contacts manager built with Next.js',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
