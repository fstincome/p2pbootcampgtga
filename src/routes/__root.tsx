import { usePublicProjects } from "@/components/PublicProjects";
import { useSelectedParticipants } from "@/components/SelectedParticipants";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  Outlet,
  Link,
  createRootRouteWithContext,
  useRouter,
  HeadContent,
  Scripts,
} from "@tanstack/react-router";
import { Toaster } from "@/components/ui/sonner";
import { I18nProvider, ThemeProvider, useI18n, useTheme } from "@/lib/providers";
import { SettingsToggles } from "@/components/SettingsToggles";
import { InstallPwaPrompt } from "@/components/InstallPwaPrompt";

import appCss from "../styles.css?url";

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-primary">404</h1>
        <p className="mt-4 text-muted-foreground">Page not found.</p>
        <Link to="/" className="mt-6 inline-flex rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
          Home
        </Link>
      </div>
    </div>
  );
}

function ErrorComponent({ error, reset }: { error: Error; reset: () => void }) {
  console.error(error);
  const router = useRouter();
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-semibold">An error occurred</h1>
        <p className="mt-2 text-sm text-muted-foreground">Please try again.</p>
        <button
          onClick={() => { router.invalidate(); reset(); }}
          className="mt-6 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
        >Retry</button>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "BOOTCAMP GITEGA — BitDevs Gitega" },
      { name: "description", content: "Cinq jours de formation pratique et de hackathon Bitcoin à Gitega, du 21 au 25 septembre 2026." },
      { property: "og:title", content: "BOOTCAMP GITEGA — BitDevs Gitega" },
      { name: "twitter:title", content: "BOOTCAMP GITEGA — BitDevs Gitega" },
      { property: "og:description", content: "Cinq jours de formation pratique et de hackathon Bitcoin à Gitega, du 21 au 25 septembre 2026." },
      { name: "twitter:description", content: "Cinq jours de formation pratique et de hackathon Bitcoin à Gitega, du 21 au 25 septembre 2026." },
      { name: "twitter:card", content: "summary_large_image" },
      { property: "og:type", content: "website" },
    ],
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "icon", type: "image/png", href: "/icon-512.png" },
      { rel: "apple-touch-icon", href: "/icon-512.png" },
      { rel: "manifest", href: "/manifest.json" },
      { rel: "theme-color", href: "oklch(0.72 0.18 55)" },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: React.ReactNode }) {
  // Inline script avoids theme flash before React hydrates.
  const noFlash = `(function(){try{var t=localStorage.getItem('theme');if(!t){t=matchMedia('(prefers-color-scheme: light)').matches?'light':'dark';}document.documentElement.classList.remove('light','dark');document.documentElement.classList.add(t);}catch(e){document.documentElement.classList.add('dark');}})();`;
  return (
    <html lang="fr" className="dark" suppressHydrationWarning>
      <head>
        <HeadContent />
        <script dangerouslySetInnerHTML={{ __html: noFlash }} />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();
  return (
    <ThemeProvider>
      <I18nProvider>
        <QueryClientProvider client={queryClient}>
          <SiteNav />
          <Outlet />
          <ThemedToaster />
          <InstallPwaPrompt />
          <SiteFooter />
        </QueryClientProvider>
      </I18nProvider>
    </ThemeProvider>
  );
}

function SiteFooter() {
  return (
    <footer className="border-t border-border/60 bg-background/80 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <p className="text-xs text-muted-foreground">
          © {new Date().getFullYear()} Bootcamp Gitega.
        </p>
        <SettingsToggles />
      </div>
    </footer>
  );
}

function ThemedToaster() {
  const { theme } = useTheme();
  return <Toaster theme={theme} />;
}

function SiteNav() {
  const { t, lang } = useI18n();
  const publicProjects = usePublicProjects();
  const selectedParticipants = useSelectedParticipants();
  const awardedProjects = publicProjects.filter((project) => project.award_rank === 1 || project.award_rank === 2);
  return (
    <header className="sticky top-0 z-50 border-b border-border/60 bg-background/80 backdrop-blur">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <div className="flex items-center gap-3">
          <Link to="/" className="flex items-center gap-2 font-mono text-sm font-bold">
            <span className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground">₿</span>
            <span>BOOTCAMP<span className="text-primary"> GITEGA</span></span>
          </Link>
          <SettingsToggles />
        </div>
        <div className="hidden items-center gap-8 text-sm md:flex">
          <Link to="/program" className="text-muted-foreground hover:text-foreground">{t("nav.program")}</Link>
          <Link to="/agenda" className="text-muted-foreground hover:text-foreground">{t("nav.agenda")}</Link>
          <Link to="/trainers" className="text-muted-foreground hover:text-foreground">{t("nav.trainers")}</Link>
          {selectedParticipants.length > 0 && <Link to="/participants" className="text-muted-foreground hover:text-foreground">{t("nav.participants")}</Link>}
          {awardedProjects.length >= 2 && <a href="/#primes" className="font-semibold text-primary hover:text-foreground">{lang === "en" ? "Awarded" : "Primés"}</a>}
          {publicProjects.length > 0 && <Link to="/projects" className="text-muted-foreground hover:text-foreground">{t("nav.projects")}</Link>}
          <Link to="/contact" className="text-muted-foreground hover:text-foreground">{t("nav.contacts")}</Link>
        </div>
        <div className="flex items-center gap-2">
          <Link to="/register" className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:bg-primary/90">
            {t("nav.register")}
          </Link>
        </div>
      </nav>
    </header>
  );
}
