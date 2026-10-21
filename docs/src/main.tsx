import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createRootRoute, createRoute, createRouter, RouterProvider } from '@tanstack/react-router';
import { DocumentationPage } from './page';
import './styles.css';

const rootRoute = createRootRoute();
const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: DocumentationPage,
});
const router = createRouter({
  routeTree: rootRoute.addChildren([indexRoute]),
  basepath: import.meta.env.BASE_URL,
  defaultNotFoundComponent: () => <main><h1>Page not found</h1><a href={import.meta.env.BASE_URL}>Return to the field guide</a></main>,
});

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

createRoot(document.getElementById('root')!).render(
  <StrictMode><RouterProvider router={router} /></StrictMode>,
);
