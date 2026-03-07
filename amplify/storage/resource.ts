import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'bhashalens-exports',
  access: (allow) => ({
    'exports/*': [
      allow.authenticated.to(['read', 'write', 'delete']),
      allow.guest.to(['read']) 
    ],
  })
});
