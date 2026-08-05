import './globals.css'

export const metadata = {
  title: 'Tasks List',
  description: 'A task list built with Next.js',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
