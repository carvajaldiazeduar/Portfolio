import './globals.css'

export const metadata = {
  title: 'Inboxes',
  description: 'A simple messaging inbox built with Next.js',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
