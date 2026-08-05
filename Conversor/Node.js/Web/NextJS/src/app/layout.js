import './globals.css'

export const metadata = {
  title: 'Conversor',
  description: 'A unit conversor built with Next.js',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
