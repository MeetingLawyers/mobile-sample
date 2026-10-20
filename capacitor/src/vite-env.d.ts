/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly ML_API_KEY?: string;
  readonly ML_USER_ID?: string;
  readonly ML_ENVIRONMENT?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
