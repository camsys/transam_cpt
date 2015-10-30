CREATE TABLE activity_line_items  (
	id                	int(11) AUTO_INCREMENT NOT NULL,
	object_key        	varchar(12) NOT NULL,
	capital_project_id	int(11) NOT NULL,
	team_ali_code_id  	int(11) NOT NULL,
	name              	varchar(80) NOT NULL,
	anticipated_cost  	int(11) NOT NULL,
	estimated_cost    	int(11) NULL,
	cost_justification	text NULL,
	active            	tinyint(1) NULL,
	created_at        	datetime NULL,
	updated_at        	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX activity_line_items_idx2 USING BTREE
	ON activity_line_items(capital_project_id)
GO
CREATE INDEX activity_line_items_idx1 USING BTREE
	ON activity_line_items(capital_project_id, object_key)
GO
CREATE TABLE activity_line_items_assets  (
	id                   	int(11) AUTO_INCREMENT NOT NULL,
	activity_line_item_id	int(11) NOT NULL,
	asset_id             	int(11) NOT NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX activity_line_items_assets_idx1 USING BTREE
	ON activity_line_items_assets(activity_line_item_id, asset_id)
GO

CREATE TABLE capital_project_types  (
	id         	int(11) AUTO_INCREMENT NOT NULL,
	name       	varchar(64) NOT NULL,
	code       	varchar(4) NOT NULL,
	description	varchar(254) NOT NULL,
	active     	tinyint(1) NOT NULL,
	PRIMARY KEY(id)
)
GO
CREATE TABLE capital_projects  (
	id                            	int(11) AUTO_INCREMENT NOT NULL,
	object_key                    	varchar(12) NOT NULL,
	fy_year                       	int(11) NOT NULL,
	project_number                	varchar(32) NOT NULL,
	organization_id               	int(11) NOT NULL,
	team_ali_code_id              	int(11) NOT NULL,
	capital_project_type_id       	int(11) NOT NULL,
	sogr	                          tinyint(1) NOT NULL,
	multi_year                      tinyint(1) NOT NULL,
	state                           varchar(32) NOT NULL,
	title                         	varchar(80) NOT NULL,
	description                   	varchar(254) NULL,
	justification                 	varchar(254) NULL,
	emergency                     	tinyint(1) NULL,
	active                        	tinyint(1) NULL,
	created_at                    	datetime NULL,
	updated_at                    	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX capital_projects_idx1 USING BTREE
	ON capital_projects(organization_id, object_key)
GO
CREATE INDEX capital_projects_idx2 USING BTREE
	ON capital_projects(organization_id, project_number)
GO
CREATE INDEX capital_projects_idx3 USING BTREE
	ON capital_projects(organization_id, fy_year)
GO
CREATE INDEX capital_projects_idx4 USING BTREE
	ON capital_projects(organization_id, capital_project_type_id)
GO
CREATE TABLE milestone_types  (
	id                 	int(11) AUTO_INCREMENT NOT NULL,
	name               	varchar(64) NOT NULL,
	description        	varchar(255) NOT NULL,
	is_vehicle_delivery	tinyint(1) NOT NULL,
	active             	tinyint(1) NOT NULL,
	PRIMARY KEY(id)
)
GO
CREATE TABLE milestones  (
	id                   	int(11) AUTO_INCREMENT NOT NULL,
	object_key           	varchar(12) NOT NULL,
	activity_line_item_id	int(11) NOT NULL,
	milestone_type_id    	int(11) NOT NULL,
	milestone_date       	date NULL,
	comments             	varchar(254) NULL,
	created_by_id        	int(11) NULL,
	created_at           	datetime NULL,
	updated_at           	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX milestones_idx1 USING BTREE
	ON milestones(activity_line_item_id, object_key)
GO
CREATE INDEX milestones_idx2 USING BTREE
	ON milestones(activity_line_item_id, milestone_date)
GO
CREATE TABLE funding_plans  (
	id                   	int(11) AUTO_INCREMENT NOT NULL,
	object_key           	varchar(12) NOT NULL,
	activity_line_item_id	int(11) NOT NULL,
	funding_source_id    	int(11) NOT NULL,
	amount        				int(11) NOT NULL,
	created_at           	datetime NULL,
	updated_at           	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX funding_plans_idx1 ON funding_plans(object_key)
GO
CREATE INDEX funding_plans_idx2 ON funding_plans(activity_line_item_id, funding_source_id)
GO
INSERT INTO capital_project_types(active, name, code, description)
    VALUES(1, 'Replacement', 'R', 'Replacement Project')
GO
INSERT INTO capital_project_types(active, name, code, description)
    VALUES(1, 'Expansion', 'E', 'Expansion Project')
GO
INSERT INTO capital_project_types(active, name, code, description)
    VALUES(1, 'Improvement', 'I', 'Improvement Project')
GO
INSERT INTO capital_project_types(active, name, code, description)
    VALUES(1, 'Demonstration', 'D', 'Demonstration Project')
GO
INSERT INTO milestone_types(active, name, is_vehicle_delivery, description)
    VALUES(1, 'Out for Bid', 0, 'Out for Bid')
GO
INSERT INTO milestone_types(active, name, is_vehicle_delivery, description)
    VALUES(1, 'Contract Awarded', 0, 'Contract Awarded')
GO
INSERT INTO milestone_types(active, name, is_vehicle_delivery, description)
    VALUES(1, 'Notice to Proceed', 0, 'Notice to Proceed')
GO
INSERT INTO milestone_types(active, name, is_vehicle_delivery, description)
    VALUES(1, 'First Vehicle Delivered', 1, 'First Vehicle Delivered')
GO
INSERT INTO milestone_types(active, name, is_vehicle_delivery, description)
    VALUES(1, 'All Vehicles Delivered', 1, 'All Vehicles Delivered')
GO
INSERT INTO milestone_types(active, name, is_vehicle_delivery, description)
    VALUES(1, 'Contract Completed', 0, 'Contract Completed')
GO
