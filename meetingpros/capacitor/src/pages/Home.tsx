import { useEffect, useState } from 'react';
import {
  IonButton,
  IonContent,
  IonHeader,
  IonInput,
  IonItem,
  IonList,
  IonNote,
  IonPage,
  IonTitle,
  IonToolbar,
} from '@ionic/react';

import { MeetingPros } from '../plugins/meeting-pros';
import type { DoctorsFeature, ProfessionalType } from '../plugins/meeting-pros';
import { BRAND_COLOR, MD_API_KEY, ML_API_KEY, ML_ENVIRONMENT, ML_USER_ID } from '../config/constants';
import './Home.css';

type SdkStatus = 'missing-credentials' | 'configuring' | 'configured' | 'authenticated';

const LIST_TYPES: ProfessionalType[] = ['lawyers', 'doctors', 'vets'];
const FEATURES: DoctorsFeature[] = ['videoCall', 'medicalHistory', 'myHealth', 'booking', 'appointments'];

const Home: React.FC = () => {
  const [status, setStatus] = useState<SdkStatus>('configuring');
  const [error, setError] = useState<string | null>(null);
  const [features, setFeatures] = useState<DoctorsFeature[]>([]);
  const [professionalHash, setProfessionalHash] = useState('');

  useEffect(() => {
    configureSdks();
  }, []);

  /// Runs a plugin call and shows its error, if any.
  const run = async (operation: () => Promise<void>) => {
    try {
      setError(null);
      await operation();
    } catch (e) {
      setError(describe(e));
    }
  };

  const loadFeatures = async () => setFeatures((await MeetingPros.availableFeatures()).features);

  const configureSdks = async () => {
    if (!ML_API_KEY || !MD_API_KEY || !ML_USER_ID) {
      setStatus('missing-credentials');
      return;
    }
    try {
      await MeetingPros.configure({ lawyersApiKey: ML_API_KEY, doctorsApiKey: MD_API_KEY, environment: ML_ENVIRONMENT });
      await MeetingPros.configureTheme({ primaryColor: BRAND_COLOR });
      const { authenticated } = await MeetingPros.isAuthenticated();
      setStatus(authenticated ? 'authenticated' : 'configured');
      if (authenticated) await loadFeatures();
    } catch (e) {
      setStatus('missing-credentials');
      setError(describe(e));
    }
  };

  const signIn = () =>
    run(async () => {
      await MeetingPros.authenticate({ userId: ML_USER_ID });
      setStatus('authenticated');
      await loadFeatures();
    });

  const signOut = () =>
    run(async () => {
      await MeetingPros.logout();
      setFeatures([]);
      setStatus('configured');
    });

  const signedIn = status === 'authenticated';

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>MeetingPros Sample</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent fullscreen className="ion-padding">
        <p data-testid="sdk-status">
          Status: <strong>{describeStatus(status)}</strong> ({ML_ENVIRONMENT})
        </p>
        {status === 'missing-credentials' && (
          <IonNote color="warning">
            Set ML_API_KEY, MD_API_KEY and ML_USER_ID in the repo-root <code>.env</code>, then rebuild.
          </IonNote>
        )}
        {error && (
          <IonNote color="danger" data-testid="sdk-error">
            {error}
          </IonNote>
        )}

        <IonList inset={false}>
          <IonButton expand="block" onClick={signIn} disabled={status !== 'configured'} data-testid="sign-in">
            Sign in
          </IonButton>

          {LIST_TYPES.map((type) => (
            <IonButton
              key={type}
              expand="block"
              onClick={() => run(() => MeetingPros.openProfessionalList({ type }))}
              disabled={!signedIn}
            >
              Open {type} list
            </IonButton>
          ))}

          <IonItem>
            <IonInput
              label="Lawyer's professional hash"
              labelPlacement="stacked"
              placeholder="Optional: open a lawyer's chat directly"
              value={professionalHash}
              onIonInput={(e) => setProfessionalHash(e.detail.value ?? '')}
            />
          </IonItem>
          <IonButton
            expand="block"
            fill="outline"
            onClick={() => run(() => MeetingPros.openLawyerChat({ professionalHash }))}
            disabled={!signedIn || !professionalHash}
          >
            Open lawyer chat
          </IonButton>

          {FEATURES.map((feature) => (
            <IonButton
              key={feature}
              expand="block"
              fill="outline"
              onClick={() => run(() => MeetingPros.openFeature({ feature }))}
              disabled={!signedIn || !features.includes(feature)}
            >
              Open {feature}
            </IonButton>
          ))}

          <IonButton expand="block" fill="clear" color="medium" onClick={signOut} disabled={!signedIn} data-testid="sign-out">
            Sign out
          </IonButton>
        </IonList>
      </IonContent>
    </IonPage>
  );
};

/// Human-readable label for each SDK status.
const describeStatus = (status: SdkStatus): string => {
  switch (status) {
    case 'missing-credentials':
      return 'Missing credentials';
    case 'configuring':
      return 'Configuring…';
    case 'configured':
      return 'Configured, not signed in';
    case 'authenticated':
      return 'Signed in';
  }
};

/// Extracts a readable message from a plugin error.
const describe = (error: unknown): string => (error instanceof Error ? error.message : String(error));

export default Home;
