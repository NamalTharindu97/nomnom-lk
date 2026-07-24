export default function TermsPage() {
  return (
    <main className="min-h-screen bg-background p-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Terms of Service</h1>
      <p className="text-muted-foreground mb-2">Last updated: 2026</p>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Acceptance of Terms</h2>
        <p>By using NomNom LK, you agree to these terms. If you do not agree, please do not use the service.</p>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Service Description</h2>
        <p>NomNom LK is a food offers discovery platform for users in Sri Lanka. We aggregate and display promotional offers from restaurants across the country.</p>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">User Accounts</h2>
        <ul className="list-disc pl-6 mt-2 space-y-1">
          <li>You must provide accurate information when creating an account</li>
          <li>You are responsible for maintaining the confidentiality of your account</li>
          <li>You must be at least 13 years old to use this service</li>
        </ul>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Prohibited Activities</h2>
        <ul className="list-disc pl-6 mt-2 space-y-1">
          <li>Using the service for any unlawful purpose</li>
          <li>Attempting to gain unauthorized access to our systems</li>
          <li>Interfering with the proper working of the service</li>
          <li>Creating multiple accounts for abusive purposes</li>
        </ul>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Limitation of Liability</h2>
        <p>NomNom LK is provided &quot;as is&quot; without warranties. We are not responsible for the accuracy of offer information provided by restaurants.</p>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Contact</h2>
        <p>For questions about these terms, contact us at <a href="mailto:support@nomnom.lk" className="text-primary underline">support@nomnom.lk</a>.</p>
      </section>
    </main>
  )
}
