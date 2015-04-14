class X2Importer < Struct.new(:school_scope, :grade_scope)

  def connect_to_x2
    ActiveRecord::Base.establish_connection(:x2_database_development)
    @student_sql = "SELECT DISTINCT * from student where STD_ENROLLMENT_STATUS = 'Active' and STD_ID_STATE is not NULL"
    @school_sql = "SELECT * from school"
    @student_result = ActiveRecord::Base.connection.exec_query(@student_sql).to_hash
    @school_result = ActiveRecord::Base.connection.exec_query(@school_sql).to_hash
    ActiveRecord::Base.connection.close
    return [@student_result, @school_result]
  end

  def import(student_result, school_result)
    ActiveRecord::Base.establish_connection(:development)
    student_result.each do |row|
      school_result.each do |school_row|
        if school_row["SKL_OID"] == row["STD_SKL_OID"]
          school_local_id = school_row["SKL_SCHOOL_ID"]
          grade = row["STD_GRADE_LEVEL"]
          if grade == grade_scope && school_local_id == school_scope.local_id
            student = create_or_update_student(row)
            homeroom_name = row["STD_HOMEROOM"]
            create_or_update_homeroom(student, homeroom_name)
          end
        end
      end
    end
  end

  def create_or_update_student(row)
    state_id = row["STD_ID_STATE"]
    student = Student.where(state_identifier: state_id).first_or_create!
    home_language = row["STD_HOME_LANGUAGE_CODE"]
    student.update_attributes(
      home_language: home_language
    )
    return student
  end

  def assign_student_to_homeroom(student, homeroom_name)
    homeroom = Homeroom.where(name: homeroom_name).first_or_create!
    student.homeroom_id = homeroom.id
    student.save
  end
end