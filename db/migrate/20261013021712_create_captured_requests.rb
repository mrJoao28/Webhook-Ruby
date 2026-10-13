class CreateCapturedRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :captured_requests do |t|
      t.references :endpoint, null: false, foreign_key: true
      t.string :http_method
      t.json :headers
      t.text :body
      t.json :query_params
      t.string :ip
      t.string :content_type

      t.timestamps
    end
  end
end
