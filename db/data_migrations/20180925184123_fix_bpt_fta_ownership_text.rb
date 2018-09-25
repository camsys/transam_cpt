class FixBptFtaOwnershipText < ActiveRecord::DataMigration
  def up
    ftas = FtaOwnershipType.all
    ftas.each {|fta|
      if(fta.code == 'OOPE')
        fta.name = 'Owned outright by private entity'
        fta.code = 'OOPE'
        fta.description = 'Owned outright by private entity'
        fta.save
      end
      if(fta.code == 'OOPA')
        fta.name = 'Owned outright by public agency'
        fta.code = 'OOPA'
        fta.description = 'Owned outright by public agency'
        fta.save
      end

      if(fta.code == 'TLPE')
        fta.name = 'True lease by private entity'
        fta.code = 'TLPE'
        fta.description = 'True lease by private entity'
        fta.save
      end
      if(fta.code == 'TLPA')
        fta.name = 'True lease by public agency'
        fta.code = 'TLPA'
        fta.description = 'True lease by public agency'
        fta.save
      end

      if(fta.code == 'OTHR')
        fta.name = 'Other'
        fta.code = 'OTHR'
        fta.description = 'Other'
        fta.save
      end

      if(fta.code == 'LRPA')
        fta.name = 'Leased or borrowed from related parties by a public agency'
        fta.code = 'LRPA'
        fta.description = 'Leased or borrowed from related parties by a public agency'
        fta.save
      end


      if(fta.code == 'LRPE')
        fta.name = 'Leased or borrowed from related parties by a private entity'
        fta.code = 'LRPE'
        fta.description = 'Leased or borrowed from related parties by a private entity'
        fta.save
      end

      if(fta.code == 'LPPA')
        fta.name = 'Leased under lease purchase agreement by a public agency'
        fta.code = 'LPPA'
        fta.description = 'Leased under lease purchase agreement by a public agency'
        fta.save
      end

      if(fta.code == 'LPPE')
        fta.name = 'Leased under lease purchase agreement by a private entity'
        fta.code = 'LPPE'
        fta.description = 'Leased under lease purchase agreement by a private entity'
        fta.save
      end
    }


  end
end
