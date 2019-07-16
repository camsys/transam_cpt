-- RUN THIS. IF YOU HAVE TRANSIT DO NOT RUN THE TABLE VIEWS CREATION SCRIPT THERE BECAUSE THIS ONE IS BETTER!!!!!!!
-- ----------------------------------------------------------------------------------------------------------------
DROP VIEW if exists all_assets_recent_asset_events_for_type_view;
CREATE OR REPLACE VIEW all_assets_recent_asset_events_for_type_view AS
      SELECT
        aet.id AS asset_event_type_id, aet.class_name AS asset_event_name, Max(ae.created_at) AS asset_event_created_time, ae.base_transam_asset_id, Max(ae.id) AS asset_event_id
      FROM asset_events AS ae
      LEFT JOIN asset_event_types AS aet ON aet.id = ae.asset_event_type_id
      LEFT JOIN transam_assets AS ta  ON ta.id = ae.base_transam_asset_id
      WHERE aet.id IN (
        SELECT id FROM asset_event_types WHERE class_name IN ('ConditionUpdateEvent', 'MaintenanceProviderUpdateEvent', 'ServiceStatusUpdateEvent',
          'RehabilitationUpdateEvent', 'MileageUpdateEvent', 'ReplacementStatusUpdateEvent', 'PerformanceRestrictionUpdateEvent')
      )
      GROUP BY aet.id, ae.base_transam_asset_id;