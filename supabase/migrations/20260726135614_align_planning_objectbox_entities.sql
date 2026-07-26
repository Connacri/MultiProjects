-- This migration intentionally resets the public application schema.
-- The source of truth is lib/objectbox-model.json (43 entities).
-- All existing public application tables are dropped with their data by the
-- deployment runner before this declarative schema is created.

CREATE TABLE public.cruds (
  id bigint PRIMARY KEY, created_by bigint NOT NULL DEFAULT 0,
  updated_by bigint NOT NULL DEFAULT 0, deleted_by bigint NOT NULL DEFAULT 0,
  is_synced boolean NOT NULL DEFAULT false, date_creation timestamptz,
  synced_at timestamptz, derniere_modification timestamptz, date_deleting timestamptz
);

CREATE TABLE public.branches (id bigint PRIMARY KEY, branch_nom text NOT NULL);
CREATE TABLE public.annonces (id bigint PRIMARY KEY, titre text NOT NULL, prix text NOT NULL, lien text NOT NULL, categorie text NOT NULL);
CREATE TABLE public.board_bases (
  id bigint PRIMARY KEY, name text NOT NULL, code text NOT NULL, description text NOT NULL,
  photos_json text NOT NULL, includes_breakfast boolean NOT NULL DEFAULT false,
  includes_lunch boolean NOT NULL DEFAULT false, includes_dinner boolean NOT NULL DEFAULT false,
  includes_snacks boolean NOT NULL DEFAULT false, includes_drinks boolean NOT NULL DEFAULT false,
  includes_alcoholic_drinks boolean NOT NULL DEFAULT false, includes_room_service boolean NOT NULL DEFAULT false,
  includes_minibar boolean NOT NULL DEFAULT false, price_per_person double precision NOT NULL DEFAULT 0,
  child_discount double precision NOT NULL DEFAULT 0, is_active boolean NOT NULL DEFAULT false,
  sort_order bigint NOT NULL DEFAULT 0, notes text NOT NULL
);
CREATE TABLE public.clients (
  id bigint PRIMARY KEY, qr text NOT NULL, nom text NOT NULL, phone text NOT NULL,
  adresse text NOT NULL, description text NOT NULL, derniere_modification timestamptz,
  is_synced boolean NOT NULL DEFAULT false, synced_at timestamptz,
  crud_id bigint REFERENCES public.cruds(id)
);
CREATE TABLE public.fournisseurs (
  id bigint PRIMARY KEY, qr text NOT NULL, nom text NOT NULL, phone text NOT NULL,
  adresse text NOT NULL, derniere_modification timestamptz, is_synced boolean NOT NULL DEFAULT false,
  synced_at timestamptz, crud_id bigint REFERENCES public.cruds(id)
);
CREATE TABLE public.produits (
  id bigint PRIMARY KEY, qr text NOT NULL, image text NOT NULL, nom text NOT NULL,
  description text NOT NULL, prix_vente double precision NOT NULL DEFAULT 0, tax double precision NOT NULL DEFAULT 0,
  qty_partiel bigint NOT NULL DEFAULT 0, price_partiel_vente double precision NOT NULL DEFAULT 0,
  minim_stock bigint NOT NULL DEFAULT 0, alert_peremption bigint NOT NULL DEFAULT 0,
  is_synced boolean NOT NULL DEFAULT false, synced_at timestamptz, derniere_modification timestamptz,
  crud_id bigint REFERENCES public.cruds(id), qr_code_list text NOT NULL
);
CREATE TABLE public.approvisionnements (
  id bigint PRIMARY KEY, quantite double precision NOT NULL DEFAULT 0, is_synced boolean NOT NULL DEFAULT false,
  prix_achat double precision NOT NULL DEFAULT 0, derniere_modification timestamptz, synced_at timestamptz,
  date_peremption timestamptz, produit_id bigint REFERENCES public.produits(id),
  fournisseur_id bigint REFERENCES public.fournisseurs(id), crud_id bigint REFERENCES public.cruds(id)
);
CREATE TABLE public.deleted_products (
  id bigint PRIMARY KEY, name text NOT NULL, description text NOT NULL, price double precision NOT NULL DEFAULT 0,
  quantity bigint NOT NULL DEFAULT 0, delais_peremption bigint NOT NULL DEFAULT 0,
  derniere_modification timestamptz, is_synced boolean NOT NULL DEFAULT false, synced_at timestamptz,
  crud_id bigint REFERENCES public.cruds(id)
);
CREATE TABLE public.documents (
  id bigint PRIMARY KEY, type text NOT NULL, qr_reference text NOT NULL, impayer double precision NOT NULL DEFAULT 0,
  derniere_modification timestamptz, is_synced boolean NOT NULL DEFAULT false, synced_at timestamptz,
  date timestamptz, client_id bigint REFERENCES public.clients(id), fournisseur_id bigint REFERENCES public.fournisseurs(id),
  crud_id bigint REFERENCES public.cruds(id), montant_verse double precision NOT NULL DEFAULT 0
);
CREATE TABLE public.ligne_documents (
  id bigint PRIMARY KEY, quantite double precision NOT NULL DEFAULT 0, prix_unitaire double precision NOT NULL DEFAULT 0,
  derniere_modification timestamptz, is_synced boolean NOT NULL DEFAULT false, synced_at timestamptz,
  produit_id bigint REFERENCES public.produits(id), facture_id bigint REFERENCES public.documents(id)
);
CREATE TABLE public.employees (id bigint PRIMARY KEY, full_name text NOT NULL, phone_number text NOT NULL, email text NOT NULL, photos_json text NOT NULL);
CREATE TABLE public.guests (id bigint PRIMARY KEY, full_name text NOT NULL, phone_number text NOT NULL, email text NOT NULL, id_card_number text NOT NULL, nationality text NOT NULL, photos_json text NOT NULL);
CREATE TABLE public.seasonal_pricings (
  id bigint PRIMARY KEY, name text NOT NULL, start_date timestamptz, end_date timestamptz,
  multiplier double precision NOT NULL DEFAULT 0, photos_json text NOT NULL, application_type text NOT NULL,
  target_ids text NOT NULL, is_active boolean NOT NULL DEFAULT false, priority bigint NOT NULL DEFAULT 0, description text NOT NULL
);
CREATE TABLE public.hotels (
  id bigint PRIMARY KEY, name text NOT NULL, floors bigint NOT NULL DEFAULT 0, rooms_per_floor bigint NOT NULL DEFAULT 0,
  avoided_numbers text NOT NULL, photos_json text NOT NULL, selected_seasonal_pricing_id bigint REFERENCES public.seasonal_pricings(id)
);
CREATE TABLE public.room_categories (
  id bigint PRIMARY KEY, name text NOT NULL, code text NOT NULL, description text NOT NULL, bed_type text NOT NULL,
  capacity bigint NOT NULL DEFAULT 0, standing text NOT NULL, view_type text NOT NULL, amenities text NOT NULL,
  base_price double precision NOT NULL DEFAULT 0, season_multiplier double precision NOT NULL DEFAULT 0,
  weekend_multiplier double precision NOT NULL DEFAULT 0, allows_extra_bed boolean NOT NULL DEFAULT false,
  extra_bed_price double precision NOT NULL DEFAULT 0, is_active boolean NOT NULL DEFAULT false, sort_order bigint NOT NULL DEFAULT 0
);
CREATE TABLE public.rooms (id bigint PRIMARY KEY, code text NOT NULL, status text NOT NULL, photos_json text NOT NULL, category_id bigint REFERENCES public.room_categories(id), hotel_id bigint REFERENCES public.hotels(id));
CREATE TABLE public.extra_services (
  id bigint PRIMARY KEY, name text NOT NULL, code text NOT NULL, description text NOT NULL, category text NOT NULL,
  photos_json text NOT NULL, price double precision NOT NULL DEFAULT 0, pricing_unit text NOT NULL,
  is_percentage boolean NOT NULL DEFAULT false, requires_advance_booking boolean NOT NULL DEFAULT false,
  advance_hours bigint NOT NULL DEFAULT 0, max_quantity bigint NOT NULL DEFAULT 0, is_active boolean NOT NULL DEFAULT false,
  sort_order bigint NOT NULL DEFAULT 0, notes text NOT NULL, is_package boolean NOT NULL DEFAULT false, package_includes text NOT NULL
);
CREATE TABLE public.reservations (
  id bigint PRIMARY KEY, room_id bigint REFERENCES public.rooms(id), receptionist_id bigint REFERENCES public.employees(id),
  board_basis_id bigint REFERENCES public.board_bases(id), seasonal_pricing_id bigint REFERENCES public.seasonal_pricings(id),
  seasonal_multiplier double precision NOT NULL DEFAULT 0, "from" timestamptz, "to" timestamptz,
  price_per_night double precision NOT NULL DEFAULT 0, status text NOT NULL, discount_percent double precision NOT NULL DEFAULT 0,
  discount_amount double precision NOT NULL DEFAULT 0, discount_type text NOT NULL, discount_applied_to text NOT NULL,
  selected_discount_items text NOT NULL, cached_board_basis_price double precision NOT NULL DEFAULT 0, cached_extras_total double precision NOT NULL DEFAULT 0
);
CREATE TABLE public.reservation_extras (
  id bigint PRIMARY KEY, reservation_id bigint REFERENCES public.reservations(id), extra_service_id bigint REFERENCES public.extra_services(id),
  quantity bigint NOT NULL DEFAULT 0, unit_price double precision NOT NULL DEFAULT 0, total_price double precision NOT NULL DEFAULT 0,
  status text NOT NULL, scheduled_date timestamptz, notes text NOT NULL
);
CREATE TABLE public.conversations (
  id bigint PRIMARY KEY, conversation_id text NOT NULL UNIQUE, type_value bigint NOT NULL DEFAULT 0, title text NOT NULL,
  description text NOT NULL, avatar_path text NOT NULL, participant_node_ids text NOT NULL, creator_node_id text NOT NULL,
  created_timestamp bigint NOT NULL DEFAULT 0, last_activity_timestamp bigint NOT NULL DEFAULT 0, last_message_id text NOT NULL,
  last_message_preview text NOT NULL, unread_count bigint NOT NULL DEFAULT 0, message_count bigint NOT NULL DEFAULT 0,
  is_archived boolean NOT NULL DEFAULT false, is_deleted boolean NOT NULL DEFAULT false, is_pinned boolean NOT NULL DEFAULT false,
  is_muted boolean NOT NULL DEFAULT false, last_sync_timestamp bigint NOT NULL DEFAULT 0, metadata text NOT NULL
);
CREATE TABLE public.conversation_participants (id bigint PRIMARY KEY, conversation_id text NOT NULL, node_id text NOT NULL, display_name text NOT NULL, role text NOT NULL, joined_timestamp bigint NOT NULL DEFAULT 0, left_timestamp bigint NOT NULL DEFAULT 0, notifications_enabled boolean NOT NULL DEFAULT false, last_read_message_id text NOT NULL, last_access_timestamp bigint NOT NULL DEFAULT 0);
CREATE TABLE public.messages (id bigint PRIMARY KEY, message_id text NOT NULL UNIQUE, conversation_id text NOT NULL, from_node_id text NOT NULL, to_node_id text NOT NULL, type_value bigint NOT NULL DEFAULT 0, content text NOT NULL, media_path text NOT NULL, media_size bigint NOT NULL DEFAULT 0, media_mime_type text NOT NULL, media_duration bigint NOT NULL DEFAULT 0, sent_timestamp bigint NOT NULL DEFAULT 0, received_timestamp bigint NOT NULL DEFAULT 0, read_timestamp bigint NOT NULL DEFAULT 0, status_value bigint NOT NULL DEFAULT 0, reply_to_message_id text NOT NULL, reply_to_content text NOT NULL, reply_to_from_node_id text NOT NULL, is_favorite boolean NOT NULL DEFAULT false, is_deleted boolean NOT NULL DEFAULT false, encryption_key_id text NOT NULL, content_hash text NOT NULL, send_attempts bigint NOT NULL DEFAULT 0, last_error_message text NOT NULL);
CREATE TABLE public.message_receipts (id bigint PRIMARY KEY, message_id text NOT NULL, recipient_node_id text NOT NULL, status_value bigint NOT NULL DEFAULT 0, confirmed_timestamp bigint NOT NULL DEFAULT 0, message_hash text NOT NULL);
CREATE TABLE public.message_search_indices (id bigint PRIMARY KEY, message_id text NOT NULL, conversation_id text NOT NULL, search_content text NOT NULL, message_timestamp bigint NOT NULL DEFAULT 0, type_value bigint NOT NULL DEFAULT 0);
CREATE TABLE public.message_sync_queue (id bigint PRIMARY KEY, message_id text NOT NULL, operation bigint NOT NULL DEFAULT 0, target_node_ids text NOT NULL, attempt_count bigint NOT NULL DEFAULT 0, created_timestamp bigint NOT NULL DEFAULT 0, next_retry_timestamp bigint NOT NULL DEFAULT 0, status bigint NOT NULL DEFAULT 0, error_message text NOT NULL, priority bigint NOT NULL DEFAULT 0);
CREATE TABLE public.matches (local_id bigint PRIMARY KEY, id text NOT NULL, other_user_name text NOT NULL, other_user_photo text NOT NULL, last_message_preview text NOT NULL, last_message_at bigint NOT NULL DEFAULT 0, matched_at bigint NOT NULL DEFAULT 0);
CREATE TABLE public.profiles (local_id bigint PRIMARY KEY, id text NOT NULL, full_name text NOT NULL, age bigint NOT NULL DEFAULT 0, bio text NOT NULL, photos text NOT NULL, city text NOT NULL, distance_km double precision NOT NULL DEFAULT 0);
CREATE TABLE public.swipe_queue (id bigint PRIMARY KEY, swiped_id text NOT NULL, action bigint NOT NULL DEFAULT 0, status bigint NOT NULL DEFAULT 0, attempt_count bigint NOT NULL DEFAULT 0, created_at timestamptz);
CREATE TABLE public.users (id bigint PRIMARY KEY, photo text NOT NULL, username text NOT NULL, password text NOT NULL, email text NOT NULL, phone text NOT NULL, role text NOT NULL, derniere_modification timestamptz, is_synced boolean NOT NULL DEFAULT false, synced_at timestamptz, crud_id bigint REFERENCES public.cruds(id));

CREATE TABLE public.staffs (id bigint PRIMARY KEY, nom text NOT NULL, grade text NOT NULL, groupe text NOT NULL, equipe text NOT NULL, ordre bigint NOT NULL DEFAULT 0, branch_id bigint REFERENCES public.branches(id));
CREATE TABLE public.type_activites (id bigint PRIMARY KEY, code text NOT NULL, libelle text NOT NULL, description text NOT NULL, couleur_hex bigint NOT NULL DEFAULT 0);
CREATE TABLE public.activite_jours (id bigint PRIMARY KEY, jour bigint NOT NULL DEFAULT 0, statut text NOT NULL, staff_id bigint REFERENCES public.staffs(id));
CREATE TABLE public.time_offs (id bigint PRIMARY KEY, debut timestamptz, fin timestamptz, motif text NOT NULL, staff_id bigint REFERENCES public.staffs(id));
CREATE TABLE public.planifications (id bigint PRIMARY KEY, mois bigint NOT NULL DEFAULT 0, annee bigint NOT NULL DEFAULT 0, ordre_equipes text NOT NULL, branch_id bigint REFERENCES public.branches(id), activites_json text NOT NULL);
CREATE TABLE public.planning_hebdos (id bigint PRIMARY KEY, staff_id bigint REFERENCES public.staffs(id), dimanche text NOT NULL, lundi text NOT NULL, mardi text NOT NULL, mercredi text NOT NULL, jeudi text NOT NULL, vendredi text NOT NULL, samedi text NOT NULL, date_debut timestamptz, date_fin timestamptz);
CREATE TABLE public.planning_configurations (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), branch_id bigint NOT NULL REFERENCES public.branches(id), configuration_key text NOT NULL, version bigint NOT NULL DEFAULT 1, name text NOT NULL, team_order_json text NOT NULL, cycle_json text NOT NULL, policy bigint NOT NULL DEFAULT 0, reference_date timestamptz, reference_phase_index bigint NOT NULL DEFAULT 0, active boolean NOT NULL DEFAULT true, UNIQUE (branch_id, configuration_key, version));
CREATE TABLE public.rotation_periods (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), branch_id bigint NOT NULL REFERENCES public.branches(id), start_date timestamptz NOT NULL, end_date timestamptz, configuration_id uuid NOT NULL REFERENCES public.planning_configurations(id));
CREATE TABLE public.rotation_state_snapshots (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), branch_id bigint NOT NULL REFERENCES public.branches(id), year bigint NOT NULL, month bigint NOT NULL, revision bigint NOT NULL, state_date timestamptz NOT NULL, configuration_id uuid NOT NULL REFERENCES public.planning_configurations(id), configuration_version bigint NOT NULL, phase_index bigint NOT NULL, team_phase_by_team text NOT NULL, UNIQUE (branch_id, year, month, revision));
CREATE TABLE public.planning_snapshots (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), branch_id bigint NOT NULL REFERENCES public.branches(id), year bigint NOT NULL, month bigint NOT NULL, configuration_id uuid NOT NULL REFERENCES public.planning_configurations(id), configuration_version bigint NOT NULL, engine_version text NOT NULL, revision bigint NOT NULL, status bigint NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now(), published_at timestamptz, rotation_state_id uuid REFERENCES public.rotation_state_snapshots(id), UNIQUE (branch_id, year, month, revision));
CREATE TABLE public.planning_assignments (id bigint PRIMARY KEY, staff_id bigint NOT NULL REFERENCES public.staffs(id), date_epoch_ms bigint NOT NULL, team text NOT NULL, shift text NOT NULL, code text NOT NULL, note text NOT NULL, snapshot_id uuid NOT NULL REFERENCES public.planning_snapshots(id));
CREATE TABLE public.planning_overrides (id bigint PRIMARY KEY, snapshot_id bigint NOT NULL, staff_id bigint NOT NULL REFERENCES public.staffs(id), date_epoch_ms bigint NOT NULL, team text, shift text NOT NULL, code text, note text);
CREATE TABLE public.planning_revisions (id bigint PRIMARY KEY, revision_id text NOT NULL, base_snapshot_id text NOT NULL, effective_snapshot_id text NOT NULL, year bigint NOT NULL, month bigint NOT NULL, revision bigint NOT NULL, modified_at_epoch_ms bigint NOT NULL, modified_by text NOT NULL, changed_fields_json text NOT NULL, validated boolean NOT NULL DEFAULT false);

CREATE INDEX idx_approvisionnements_produit_id ON public.approvisionnements(produit_id);
CREATE INDEX idx_approvisionnements_fournisseur_id ON public.approvisionnements(fournisseur_id);
CREATE INDEX idx_documents_client_id ON public.documents(client_id);
CREATE INDEX idx_documents_fournisseur_id ON public.documents(fournisseur_id);
CREATE INDEX idx_reservations_room_id ON public.reservations(room_id);
CREATE INDEX idx_rooms_category_id ON public.rooms(category_id);
CREATE INDEX idx_rooms_hotel_id ON public.rooms(hotel_id);
CREATE INDEX idx_staffs_branch_id ON public.staffs(branch_id);
CREATE INDEX idx_activite_jours_staff_id ON public.activite_jours(staff_id);
CREATE INDEX idx_time_offs_staff_id ON public.time_offs(staff_id);
CREATE INDEX idx_planning_hebdos_staff_id ON public.planning_hebdos(staff_id);
CREATE INDEX idx_rotation_periods_branch_start ON public.rotation_periods(branch_id, start_date DESC);
CREATE INDEX idx_planning_assignments_snapshot_id ON public.planning_assignments(snapshot_id);
CREATE INDEX idx_planning_assignments_staff_date ON public.planning_assignments(staff_id, date_epoch_ms);
CREATE INDEX idx_planning_overrides_snapshot_staff_date ON public.planning_overrides(snapshot_id, staff_id, date_epoch_ms);
CREATE INDEX idx_rotation_state_snapshots_branch_period ON public.rotation_state_snapshots(branch_id, year, month, revision);
CREATE INDEX idx_planning_snapshots_branch_period ON public.planning_snapshots(branch_id, year, month, revision);

NOTIFY pgrst, 'reload schema';
