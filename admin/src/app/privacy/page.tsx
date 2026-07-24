export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-background p-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Privacy Policy</h1>
      <p className="text-muted-foreground mb-2">Last updated: 2026</p>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Information We Collect</h2>
        <p>NomNom LK collects only the information necessary to provide our food offers discovery service:</p>
        <ul className="list-disc pl-6 mt-2 space-y-1">
          <li>Email address and name (for account creation)</li>
          <li>Profile information you choose to provide</li>
          <li>Favorites and notification preferences</li>
          <li>Device token for push notifications (optional)</li>
        </ul>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">How We Use Your Information</h2>
        <ul className="list-disc pl-6 mt-2 space-y-1">
          <li>To provide and maintain our service</li>
          <li>To send you notifications about offers (with your consent)</li>
          <li>To improve our service based on usage patterns</li>
          <li>To communicate with you about your account</li>
        </ul>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Data Storage and Security</h2>
        <p>Your data is stored securely on encrypted cloud servers. We implement industry-standard security measures to protect your personal information from unauthorized access.</p>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Data Retention and Deletion</h2>
        <p>You can request account deletion through the app at any time. Deletion requests have a 30-day recovery period during which you can cancel the request. After 30 days, your data will be permanently deleted.</p>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Third-Party Services</h2>
        <p>We use Firebase for authentication and push notifications. Firebase's privacy policy applies to data processed through their services.</p>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Contact Us</h2>
        <p>For privacy-related inquiries, contact us at <a href="mailto:privacy@nomnom.lk" className="text-primary underline">privacy@nomnom.lk</a>.</p>
      </section>
    </main>
  )
}
